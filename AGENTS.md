# Repository Guidelines

## Project Structure & Module Organization
- `cluster/`: Minikube lifecycle scripts (`create_cluster.sh`, `delete_cluster.sh`) parameterized via `CLUSTER_NAME`, `CLUSTER_CPUS`, and `CLUSTER_MEMORY_MB`.
- `monitoring/`: Monitoring stack assets. `deploy.sh` applies all Kubernetes manifests in `monitoring/k8s/`, including Prometheus, exporters, and Grafana.
- `Makefile`: Convenience targets to orchestrate cluster creation, deployment, and port-forwarding; prefer these over running scripts directly.

## Build, Test, and Development Commands
- `make up`: Create the Minikube cluster and deploy the monitoring stack end-to-end.
- `make down`: Delete the Minikube cluster (`CLUSTER_NAME` defaults to `demo-cluster`).
- `make deploy-monitoring`: Re-apply monitoring manifests after edits; assumes the cluster already exists.
- `make port-forward-grafana` / `make port-forward-prometheus`: Expose Grafana (`:3000`) or Prometheus (`:9090`) locally.
- `./monitoring/deploy.sh`: Used by `make deploy-monitoring`; handy for targeted debugging of the deploy process.

## Coding Style & Naming Conventions
- Bash scripts use `set -euo pipefail`; keep strict mode, shellcheck-friendly patterns, and explicit `command -v` guards.
- Kubernetes YAML uses two-space indentation; keep object names short and lower-kebab-case (e.g., `prometheus`, `grafana-dashboard`).
- Prefer plain Kubernetes manifests (no Helm/operators) to stay aligned with the current stack.

## Testing & Verification
- After changes, run `make deploy-monitoring` then verify readiness: `kubectl -n monitoring get pods` and `kubectl -n monitoring rollout status deployment/kube-state-metrics`.
- Check Prometheus targets via `make port-forward-prometheus` → Status > Targets; ensure scrape intervals and labels match expectations.
- Validate Grafana provisioning with `make port-forward-grafana`; confirm the Prometheus datasource and dashboard load without manual edits.

## Commit & Pull Request Guidelines
- Commits: use concise, imperative subjects (e.g., `harden grafana provisioning`); group related manifest changes together.
- Pull requests: include a short summary, linked issue (if any), commands run (`make up`, `make deploy-monitoring`), and screenshots of Grafana if UI changes occur.
- Flag any changes that alter cluster defaults (resources, namespaces, labels) so reviewers can re-run `make up` if needed.

## Security & Configuration Tips
- Avoid committing credentials; Grafana defaults to `admin/admin`—document overrides rather than storing secrets.
- External labels and scrape settings live in `monitoring/k8s/prometheus-config.yaml`; keep cluster-identifying labels accurate for dashboards.
