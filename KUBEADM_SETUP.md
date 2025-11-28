# Using This Project with Your Existing kubeadm Cluster

This guide helps you deploy the ETL + Prometheus + Grafana demo to your existing kubeadm Kubernetes cluster running on Docker Desktop.

## Prerequisites

- Your kubeadm cluster is already running and accessible
- `kubectl` is configured and points to your cluster
- `helm` is installed
- Docker Desktop is running (for building images)

## Quick Setup

### Step 1: Verify Your Cluster Context

```bash
kubectl config current-context
```

This should show your kubeadm cluster context (not `kind-etl-demo`).

### Step 2: Build Images Locally

```bash
make build-images
```

This creates two Docker images:
- `etl-controller:local`
- `etl-worker:local`

### Step 3: Deploy Monitoring Stack

```bash
make LOAD_WITH_KIND=0 deploy-monitoring
```

This installs Prometheus and Grafana in the `monitoring` namespace using Helm.

### Step 4: Deploy ETL Workload

```bash
make LOAD_WITH_KIND=0 deploy-etl
```

This deploys the ETL controller and worker pods to the `etl-demo` namespace.

### Step 5: Access Grafana

```bash
make port-forward-grafana
```

Then visit **http://localhost:3000** in your browser.
- **Login:** admin / admin
- **Dashboard:** ETL Demo - Kubernetes

## Using a Private Registry

If your kubeadm cluster cannot pull images from Docker Desktop's local registry, push to a registry:

```bash
# Set your registry
export IMAGE_PREFIX="myregistry.example.com/etl-demo/"

# Build and push
make build-images
docker push ${IMAGE_PREFIX}etl-controller:local
docker push ${IMAGE_PREFIX}etl-worker:local

# Deploy with the registry prefix
IMAGE_PREFIX=${IMAGE_PREFIX} make LOAD_WITH_KIND=0 deploy-monitoring
IMAGE_PREFIX=${IMAGE_PREFIX} make LOAD_WITH_KIND=0 deploy-etl
```

## Troubleshooting

### Images Not Found

If pods fail to pull images, verify they're accessible:
```bash
kubectl -n etl-demo get pods
kubectl -n etl-demo describe pod <pod-name>
```

### Prometheus Has No Data

Check if Prometheus targets are healthy:
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-prometheus 9090:9090
```

Then visit http://localhost:9090/targets

### Grafana Dashboard Empty

Wait 2-3 minutes for metrics to be scraped and displayed. Check the Prometheus targets first.

## Cleanup

To remove all deployed resources:

```bash
# Remove ETL workload
kubectl delete namespace etl-demo

# Remove monitoring stack
helm uninstall kube-prometheus -n monitoring
kubectl delete namespace monitoring
```

**Note:** This does NOT delete your kubeadm cluster itself.
