# Install Flux CLI
choco install flux

# Set env variables
$env:GITHUB_USER="<github-username>"
$env:GITHUB_TOKEN="<github-token>"

# Check 
flux check --pre

# Bootstrap Flux
flux bootstrap github `
  --owner=$env:GITHUB_USER `
  --repository=cloudgen2021 `
  --branch=main `
  --path=./clusters/cloudgenAks `
  --read-write-key `
  --personal

# Clone repository app
git clone https://github.com/<github-username>/cloudgen2021.git
Set-Location .\cloudgen2021\

# Add the GitRepository info
flux create source git cloudgen-app `
  --url=https://github.com/<github-username>/cloudgen-app `
  --branch=main `
  --interval=30s `
  --export > ./clusters/cloudgenAks/cloudgen-app-source.yaml

# Deploy the application
flux create kustomization cloudgen-app `
  --source=cloudgen-app `
  --path="./kustomize" `
  --prune=true `
  --validation=client `
  --interval=5m `
  --export > ./clusters/cloudgenAks/cloudgen-app-kustomization.yaml

# Watch the kustomization
flux get all

# Check the application
kubectl get service cloudgen-app --watch

# Suspend update
flux suspend kustomization cloudgen-app

# Resume update
flux resume kustomization cloudgen-app

# Delete the application
flux delete kustomization cloudgen-app
flux delete kustomization monitoring-stack
flux uninstall

