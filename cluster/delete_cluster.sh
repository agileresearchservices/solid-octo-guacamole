#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="etl-demo"

if ! command -v kind >/dev/null 2>&1; then
  echo "kind is required. Install via https://kind.sigs.k8s.io/" >&2
  exit 1
fi

echo "Deleting kind cluster ${CLUSTER_NAME}..."
kind delete cluster --name "${CLUSTER_NAME}"
