#!/usr/bin/env bash
set -euo pipefail

echo "Deploying demo application..."

kubectl apply -f "$(dirname "$0")/k8s/namespace.yaml"
kubectl apply -f "$(dirname "$0")/k8s/deployment.yaml"

echo "Waiting for demo-app pod to be ready..."
kubectl -n demo wait --for=condition=ready pod -l app=demo-app --timeout=60s

echo ""
echo "✓ Demo app deployed successfully!"
echo "Check status: kubectl -n demo get pods"
echo "View logs: kubectl -n demo logs -l app=demo-app -f"
echo "Test metrics: kubectl -n demo port-forward svc/demo-app 8000:8000"
echo "  Then visit: http://localhost:8000/metrics"
