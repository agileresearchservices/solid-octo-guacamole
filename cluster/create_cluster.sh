#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-demo-cluster}"
CLUSTER_CPUS="${CLUSTER_CPUS:-2}"
CLUSTER_MEMORY_MB="${CLUSTER_MEMORY_MB:-2048}"

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube is required. Install via https://minikube.sigs.k8s.io/" >&2
  exit 1
fi

echo "Creating minikube cluster ${CLUSTER_NAME}..."
minikube start \
  --profile "${CLUSTER_NAME}" \
  --driver=docker \
  --cpus "${CLUSTER_CPUS}" \
  --memory "${CLUSTER_MEMORY_MB}"

echo "Cluster ready. Current context:"
kubectl config use-context "${CLUSTER_NAME}"
