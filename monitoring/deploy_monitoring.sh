#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="monitoring"
RELEASE="kube-prometheus"
VALUES_FILE="$(dirname "$0")/helm-values/kube-prometheus-values.yaml"

echo "Creating namespace ${NAMESPACE} (if not exists)..."
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo update >/dev/null

echo "Installing kube-prometheus-stack..."
echo "(This may take 2-3 minutes on first install. Please wait...)"

# Use longer timeout for kubeadm clusters
helm upgrade --install "${RELEASE}" prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  --values "${VALUES_FILE}" \
  --timeout 15m

echo ""
echo "Applying Grafana dashboard ConfigMap..."
kubectl apply -f "$(dirname "$0")/dashboard-configmap.yaml"

echo ""
cat <<'EOF'
✓ Monitoring deployed successfully!
Grafana service: kube-prometheus-grafana (namespace monitoring)
Default credentials: admin / admin
Use port-forward: kubectl -n monitoring port-forward svc/kube-prometheus-grafana 3000:80
EOF
