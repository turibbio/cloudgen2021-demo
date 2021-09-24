<#
  **Production CI/CD workflow**
  DEV: push a bug fix to the app repository
  DEV: bump the patch version and release e.g. v1.0.1
  CI: build and push a container image tagged as registry.domain/org/app:v1.0.1
  CD: pull the latest image metadata from the app registry (Flux image scanning)
  CD: update the image tag in the app manifest to v1.0.1 (Flux cluster to Git reconciliation)
  CD: deploy v1.0.1 to production clusters (Flux Git to cluster reconciliation)
  For staging environments, this features allow you to deploy the latest build of a branch, without having to manually edit the app deployment manifest in Git.

  **Staging CI/CD workflow**
  DEV: push code changes to the app repository main branch
  CI: build and push a container image tagged as ${GIT_BRANCH}-${GIT_SHA:0:7}-$(date +%s)
  CD: pull the latest image metadata from the app registry (Flux image scanning)
  CD: update the image tag in the app manifest to main-2d3fcbd-1611906956 (Flux cluster to Git reconciliation)
  CD: deploy main-2d3fcbd-1611906956 to staging clusters (Flux Git to cluster reconciliation)
#>

# Set env variables
$env:GITHUB_USER="<github-username>"
$env:GITHUB_TOKEN="<github-token>"

# Bootstrap Flux with ImageController
flux bootstrap github `
  --components-extra=image-reflector-controller,image-automation-controller `
  --owner=$env:GITHUB_USER `
  --repository=cloudgen2021 `
  --branch=main `
  --path=./clusters/cloudgenAks `
  --read-write-key `
  --personal

# Create a service principal for the secret
..\2-create-service-principal.ps1

# Create a secret for the service principal
kubectl create secret docker-registry cloudgenacrsecret `
  --namespace flux-system `
  --docker-server=<azure-container-registry-url> `
  --docker-username=$env:SP_APP_ID `
  --docker-password=$env:SP_PASSWD

# Configure image scanning
flux create image repository cloudgen-app `
  --image=<azure-container-registry-url>/cloudgen2021 `
  --interval=1m `
  --export > ./clusters/cloudgenAks/cloudgen-app-registry.yaml

# Configure image policy
flux create image policy cloudgen-app `
  --image-ref=cloudgen-app `
  --select-semver=>=0.1.0-0 `
  --export > ./clusters/cloudgenAks/cloudgen-app-policy.yaml
  
# Append this to the cloudgen-app-registry file
secretRef:
  name: cloudgenacrsecret

# Check configuration
flux reconcile kustomization flux-system --with-source
flux get image repository cloudgen-app
flux get image policy cloudgen-app

# Add image update automation
flux create image update flux-system `
  --git-repo-ref=flux-system `
  --git-repo-path="./clusters/cloudgenAks" `
  --checkout-branch=main `
  --push-branch=main `
  --author-name=flux `
  --author-email=flux@users.noreply.github.com `
  --commit-template="{{range .Updated.Images}}{{println .}}{{end}}" `
  --export > ./clusters/cloudgenAks/cloudgen-app-automation.yaml

# Check configuration
flux reconcile kustomization flux-system --with-source
flux get image repository cloudgen-app
flux get image policy cloudgen-app
flux get image update flux-system

# Delete the application
flux delete kustomization cloudgen-app
flux uninstall