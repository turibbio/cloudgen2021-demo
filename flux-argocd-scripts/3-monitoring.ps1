# Register the monitoring stack
flux create source git monitoring `
  --interval=30m `
  --url=https://github.com/fluxcd/flux2 `
  --branch=main

# Kustomization for prometheus
flux create kustomization monitoring-stack `
  --interval=1h `
  --prune=true `
  --source=monitoring `
  --path="./manifests/monitoring/kube-prometheus-stack" `
  --health-check="Deployment/kube-prometheus-stack-operator.monitoring" `
  --health-check="Deployment/kube-prometheus-stack-grafana.monitoring" `
  --export > ./clusters/cloudgenAks/cloudgen-app-monitoring.yaml

# Add grafana
flux create kustomization monitoring-config `
  --interval=1h `
  --prune=true `
  --source=monitoring `
  --path="./manifests/monitoring/monitoring-config" `
  --export > ./clusters/cloudgenAks/cloudgen-app-monitoring-config.yaml

# Open grafana
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000/d/flux-control-plane

# Clean up
kubectl delete namespace monitoring
flux delete kustomization monitoring-stack
flux delete kustomization monitoring-config