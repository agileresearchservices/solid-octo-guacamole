# Kubernetes Monitoring Demo: ETL workload + Prometheus + Grafana

This repo contains a fully reproducible local demo that provisions a kind-based Kubernetes cluster, runs a tiny ETL-like workload (controller + workers), and ships Kubernetes metrics to Prometheus/Grafana. After the setup completes, Grafana exposes a dashboard that plots CPU/memory by pod, by role, and for the entire namespace.

## Why kind?
[kind](https://kind.sigs.k8s.io/) runs Kubernetes entirely inside Docker, which keeps the demo self-contained for laptops with Docker Desktop. The cluster spins up quickly, images can be loaded directly from the host without a registry, and no VM drivers or extra hypervisors are required (unlike some minikube configurations). If you already have a cluster (e.g., kubeadm), you can skip the kind steps and use that instead—see **Using an existing cluster** below.

## Repository layout
```
cluster/                     # kind cluster config + lifecycle scripts
  create_cluster.sh
  delete_cluster.sh
  kind-config.yaml
etl/                         # ETL workloads + manifests
  controller/
    Dockerfile
    src/main.py
  worker/
    Dockerfile
    src/main.py
  k8s/
    namespace.yaml
    configmap.yaml
    controller-deployment.yaml
    worker-deployment.yaml
  deploy_etl.sh
monitoring/                  # Prometheus + Grafana deployment and dashboard
  helm-values/kube-prometheus-values.yaml
  grafana-dashboards/etl-k8s-dashboard.json
  dashboard-configmap.yaml
  deploy_monitoring.sh
Makefile                     # Convenience targets (cluster create/delete, build/load images, deploy)
README.md
```

## Prerequisites
- Docker / Docker Desktop
- `kubectl`
- `helm`
- `kind` (only if you want the bundled local cluster)

## Quick start (kind)
```bash
# 1) Create the cluster
make cluster-create

# 2) Build ETL images and load them into kind
make build-images
make load-images

# 3) Deploy Prometheus + Grafana (kube-prometheus-stack)
make deploy-monitoring

# 4) Deploy the ETL controller and workers
make deploy-etl

# 5) Port-forward Grafana (visit http://localhost:3000)
make port-forward-grafana
# login: admin / admin
```
The one-shot `make up` target performs steps 1–4.

## Using an existing cluster (e.g., kubeadm)
You can target any reachable Kubernetes cluster instead of kind:

1. Ensure your current kubeconfig context points at the cluster you want (e.g., your kubeadm cluster).
2. Build images with an optional registry prefix and push them to a registry visible to the cluster:
   ```bash
   export IMAGE_PREFIX="myregistry.example.com/etl-demo/"
   make build-images
   docker push ${IMAGE_PREFIX}etl-controller:local
   docker push ${IMAGE_PREFIX}etl-worker:local
   ```
3. Skip kind image loading by setting `LOAD_WITH_KIND=0`:
   ```bash
   make LOAD_WITH_KIND=0 deploy-monitoring
   IMAGE_PREFIX=${IMAGE_PREFIX} make LOAD_WITH_KIND=0 deploy-etl
   ```
   The `deploy_etl.sh` script will automatically apply the prefix to the controller/worker Deployments after they are created.
4. Port-forward Grafana the same way: `make port-forward-grafana`.

## Workload overview
- **Controller Deployment** (`etl-controller`): emits synthetic task logs every few seconds to simulate dispatching ETL jobs. Labeled with `app=etl-demo, role=controller`.
- **Worker Deployment** (`etl-worker`): three replicas burn a bit of CPU, then sleep with jitter to produce observable metrics. Labeled with `app=etl-demo, role=worker`.
- **Namespace**: everything ETL-related lives in `etl-demo`. Worker count is also published via the `etl-settings` ConfigMap so the controller can reference it.

### Images
Images are simple Python apps built from `etl/controller` and `etl/worker`. They’re tagged `${IMAGE_PREFIX}etl-controller:local` and `${IMAGE_PREFIX}etl-worker:local` and loaded into kind with `kind load docker-image ...` (or pushed to your own registry when using an existing cluster).

## Monitoring stack
- Installed via `helm upgrade --install kube-prometheus ...` with overrides in `monitoring/helm-values/kube-prometheus-values.yaml`.
- Grafana credentials: `admin / admin`.
- Dashboard is auto-provisioned from `monitoring/dashboard-configmap.yaml` (picked up by the Grafana sidecar via the `grafana_dashboard: "1"` label).
- Prometheus scrapes standard Kubernetes sources (kubelet/cAdvisor, kube-state-metrics), so pod CPU/memory metrics such as `container_cpu_usage_seconds_total` and `container_memory_working_set_bytes` are available automatically.

## Grafana dashboard
Dashboard name: **ETL Demo - Kubernetes** (`uid: etl-k8s`).

**Filters:** namespace, role label, pod name.

**Panels:**
- Pod CPU (mCores): `rate(container_cpu_usage_seconds_total{namespace='$namespace', pod=~'$pod'}[5m]) * 1000` grouped by pod.
- Pod Memory (MiB): `container_memory_working_set_bytes{namespace='$namespace', pod=~'$pod'} / 1024 / 1024` grouped by pod.
- Worker/namespace aggregates for CPU and memory, plus role-level rollups for controller vs worker.

After a couple of minutes, you should see both the controller and workers show activity; aggregated worker panels will reflect the sum of all worker pods.

## Tear down
```bash
make down
```
This removes the kind cluster entirely. To redeploy, run `make up` again.

## Future extension
For long-term metric and log retention, you could add OpenSearch + OpenSearch Dashboards. A minimal approach would be to deploy the official Helm charts, ship container logs with Fluent Bit, and link the dashboards from Grafana. This demo keeps the scope focused on Prometheus + Grafana for simplicity.

## Troubleshooting
- If Grafana shows no data, ensure Prometheus targets are healthy: `kubectl -n monitoring port-forward svc/kube-prometheus-prometheus 9090:9090` and check `/targets`.
- If images are not found, rerun `make load-images` for kind or push the `${IMAGE_PREFIX}` images to your registry and redeploy with `IMAGE_PREFIX` set.
- To tweak worker intensity, edit `etl/k8s/worker-deployment.yaml` environment variables (`CPU_BURN_MS`, `WORK_LOOP_SECONDS`).
