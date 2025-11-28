#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="demo-cluster"

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube is required. Install via https://minikube.sigs.k8s.io/" >&2
  exit 1
fi

echo "Deleting minikube cluster ${CLUSTER_NAME}..."
minikube delete --profile "${CLUSTER_NAME}"
