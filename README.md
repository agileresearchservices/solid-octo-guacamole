# Minimal Kubernetes Monitoring: Prometheus + Grafana

This repo stands up a Minikube cluster with a lightweight Prometheus + Grafana stack focused on observing Kubernetes itself—nodes, pods, and deployments—without any demo workload. Everything is plain Kubernetes YAML (no Helm, no operators).

## Stack
- **Prometheus**: Standalone deployment with RBAC-enabled Kubernetes service discovery.
- **Kube State Metrics**: Cluster object visibility (pods, deployments, resources).
- **Node Exporter**: Node-level CPU, memory, and filesystem metrics via DaemonSet.
- **Kubelet Scrapes**: Metrics and cAdvisor data accessed through the API server proxy.
- **Grafana**: Pre-provisioned Prometheus datasource and a single “Kubernetes Cluster Overview” dashboard.

## Layout
```
cluster/            # Minikube lifecycle scripts
monitoring/
  k8s/              # Prometheus, exporters, Grafana manifests
  deploy.sh         # Applies monitoring namespace + stack
Makefile            # Common flows (cluster + monitoring)
```

## Prerequisites
- Docker
- `kubectl`
- `minikube`

## Quick Start
```bash
# Create the cluster and deploy monitoring
make up

# Port-forward Grafana and Prometheus
make port-forward-grafana    # http://localhost:3000 (admin / admin)
make port-forward-prometheus # http://localhost:9090
```

To clean up everything (delete the cluster): `make down`

## What You Get
- Prometheus jobs for kube-state-metrics, node-exporter, kubelet metrics, and cAdvisor.
- Grafana dashboard panels for node readiness, deployment readiness, pod phases, CPU/memory usage, node CPU utilization, and filesystem availability.

## Notes
- Scrape interval defaults to 15s (`monitoring/k8s/prometheus-config.yaml`).
- Edit manifests in `monitoring/k8s/` to tweak resources or add dashboards/datasources.
