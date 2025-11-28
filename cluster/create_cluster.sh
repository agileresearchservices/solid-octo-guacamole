#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="demo-cluster"

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube is required. Install via https://minikube.sigs.k8s.io/" >&2
  exit 1
fi

echo "Creating minikube cluster ${CLUSTER_NAME}..."
minikube start \
  --profile "${CLUSTER_NAME}" \
  --driver=docker \
  --cpus 2 \
  --memory 2048

echo "Cluster ready. Current context:"
kubectl config use-context "${CLUSTER_NAME}"
