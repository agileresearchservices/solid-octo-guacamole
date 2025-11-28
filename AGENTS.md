# Repository Guidelines

## Project Structure & Module Organization
- `monitoring/` holds Prometheus, exporters, and Grafana manifests under `monitoring/k8s/`, plus the deployment helper script.
- `cluster/` contains Minikube lifecycle scripts (`create_cluster.sh`, `delete_cluster.sh`).
- `Makefile` wraps the common flows; `README.md` documents setup and usage.

## Build, Test, and Development Commands
- One-shot bring-up: `make up` (creates Minikube and deploys monitoring).
- Lifecycle: `make cluster-create` / `make cluster-delete` to manage the `demo-cluster` profile.
- Deploy stack: `make deploy-monitoring`.
- Port-forwarding: `make port-forward-grafana`, `make port-forward-prometheus`.
- No app build/test steps remain; edits are primarily YAML.

## Coding Style & Naming Conventions
- Kubernetes: keep manifests minimal and namespaced to `monitoring`; label resources with `app=` for selectors (e.g., `prometheus`, `grafana`, `node-exporter`).
- Use consistent indentation (2 spaces) in YAML; group related resources in the same file when they deploy together.
- Prefer small, composable manifests in `monitoring/k8s/` with clear comments when behavior is non-obvious.

## Testing Guidelines
- Smoke-test changes on Minikube: `make up`, then verify `kubectl -n monitoring get pods`, Prometheus targets (`/targets`), and Grafana dashboard data.
- For dashboard tweaks, capture a quick screenshot and note the Prometheus queries you changed.

## Commit & Pull Request Guidelines
- Use short, imperative commit subjects (e.g., “Add kubelet cadvisor scrape”); aim for <72 chars.
- Follow `.github/pull_request_template.md`: describe changes, link issues, and list tests run (commands, environments).
- Mention namespaces touched and any new RBAC, ports, or credentials. Do not commit secrets; keep admin creds in Kubernetes Secrets as shown.
