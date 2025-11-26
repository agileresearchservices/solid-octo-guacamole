#!/usr/bin/env bash
set -euo pipefail

IMAGE_PREFIX="${IMAGE_PREFIX:-}"

kubectl apply -f "$(dirname "$0")/k8s/namespace.yaml"
kubectl apply -f "$(dirname "$0")/k8s/configmap.yaml"
kubectl apply -f "$(dirname "$0")/k8s/controller-deployment.yaml"
kubectl apply -f "$(dirname "$0")/k8s/worker-deployment.yaml"

if [[ -n "${IMAGE_PREFIX}" ]]; then
  echo "Overriding deployment images with prefix '${IMAGE_PREFIX}'"
  kubectl -n etl-demo set image deployment/etl-controller controller="${IMAGE_PREFIX}etl-controller:local"
  kubectl -n etl-demo set image deployment/etl-worker worker="${IMAGE_PREFIX}etl-worker:local"
fi

kubectl -n etl-demo get pods -l app=etl-demo
