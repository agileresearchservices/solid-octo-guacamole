#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="monitoring"

echo "Creating namespace ${NAMESPACE}..."
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

echo "Deploying Prometheus core..."
kubectl apply -f "$(dirname "$0")/k8s/prometheus-config.yaml"
kubectl apply -f "$(dirname "$0")/k8s/prometheus.yaml"

echo "Deploying Kubernetes exporters..."
kubectl apply -f "$(dirname "$0")/k8s/kube-state-metrics.yaml"
kubectl apply -f "$(dirname "$0")/k8s/node-exporter.yaml"
kubectl -n ${NAMESPACE} rollout status deployment/kube-state-metrics --timeout=120s
kubectl -n ${NAMESPACE} rollout status daemonset/node-exporter --timeout=120s

echo "Deploying Grafana..."
kubectl apply -f "$(dirname "$0")/k8s/grafana-datasource.yaml"
kubectl apply -f "$(dirname "$0")/k8s/grafana-dashboard.yaml"
kubectl apply -f "$(dirname "$0")/k8s/grafana.yaml"

echo "Waiting for Prometheus to be ready..."
kubectl -n ${NAMESPACE} wait --for=condition=ready pod -l app=prometheus --timeout=120s

echo "Waiting for Grafana to be ready..."
kubectl -n ${NAMESPACE} wait --for=condition=ready pod -l app=grafana --timeout=120s

echo ""
echo "✓ Monitoring stack deployed successfully!"
echo ""
echo "Prometheus: kubectl -n ${NAMESPACE} port-forward svc/prometheus 9090:9090"
echo "  Then visit: http://localhost:9090"
echo ""
echo "Grafana: kubectl -n ${NAMESPACE} port-forward svc/grafana 3000:3000"
echo "  Then visit: http://localhost:3000"
echo "  Login: admin / admin"
echo "  Dashboard: 'Kubernetes Cluster Overview'"
