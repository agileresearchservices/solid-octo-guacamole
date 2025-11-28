# Repository Guidelines

## Project Structure & Module Organization
- `app/` contains the Python demo service (`src/main.py`), Dockerfile, and Kubernetes manifests under `app/k8s/`. The service exposes `/metrics` and `/health`.
- `monitoring/` holds Prometheus and Grafana manifests in `monitoring/k8s/` plus a deployment helper script.
- `cluster/` has Minikube lifecycle scripts (`create_cluster.sh`, `delete_cluster.sh`).
- `Makefile` wraps common flows; `README.md` provides the walkthrough.

## Build, Test, and Development Commands
- One-shot bring-up: `make up` (creates cluster, builds image inside Minikube, deploys app + monitoring).
- Lifecycle: `make cluster-create` / `make cluster-delete` to manage the Minikube cluster named `demo-cluster`.
- App image: `make build-image` (uses `minikube docker-env`), `make load-image` (noop for in-cluster build).
- Deployments: `make deploy-app`, `make deploy-monitoring`.
- Port-forwarding: `make port-forward-grafana`, `make port-forward-prometheus`, `make port-forward-app`.
- Quick syntax check: `make test` (runs `python -m compileall app`); unit tests: `make test-unit` (pytest over `app/tests/`). Install dev deps via `pip install -r requirements-dev.txt`.

## Coding Style & Naming Conventions
- Python: prefer PEP 8 (4-space indent, snake_case functions/vars). Keep logging informative; avoid noisy debug logs by default.
- Kubernetes: namespaces `demo` (app) and `monitoring`; label `app=demo-app`, `app=prometheus`, `app=grafana`. Keep new manifests alongside peers in `*/k8s/`.
- Env tuning lives in `app/k8s/deployment.yaml` (e.g., `WORK_LOOP_SECONDS`, `CPU_BURN_MS`, `MEMORY_ALLOC_MB`); document any new env vars in the manifest comments.

## Testing Guidelines
- Add pytest cases under `app/tests/` named `test_*.py`; use `make test-unit` locally.
- For functional validation, run the service locally with `python app/src/main.py` (exposes port 8000) or deploy to Minikube and curl `/metrics`.
- Before merging, run `make test` and `make test-unit`. If manifests change, smoke-test on Minikube: `make up` then check `kubectl -n monitoring get pods` and `kubectl -n demo get pods`.

## Commit & Pull Request Guidelines
- Git history uses short, imperative subjects (e.g., “Add Makefile test target”); follow that style, aim for <72 chars.
- Use the PR template in `.github/pull_request_template.md`: describe changes, link issues, and list tests run.
- Note how you tested (commands run, clusters used) and attach screenshots for UI/dashboard tweaks (Grafana panels).
- For YAML changes, mention namespaces touched and any new ports/credentials. Avoid committing secrets; prefer env vars or ConfigMaps.
