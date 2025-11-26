#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="etl-demo"
CONFIG_FILE="$(dirname "$0")/kind-config.yaml"

if ! command -v kind >/dev/null 2>&1; then
  echo "kind is required. Install via https://kind.sigs.k8s.io/" >&2
  exit 1
fi

echo "Creating kind cluster ${CLUSTER_NAME}..."
kind create cluster --name "${CLUSTER_NAME}" --config "${CONFIG_FILE}"

echo "Cluster ready. Current context:"
kubectl config use-context "kind-${CLUSTER_NAME}"
