# Minimal Kubernetes Monitoring: Prometheus + Grafana

This repo stands up a Minikube cluster with a lightweight Prometheus + Grafana stack focused on observing Kubernetes itself—nodes, pods, and deployments—without any demo workload. Everything is plain Kubernetes YAML (no Helm, no operators).

## Stack
- **Prometheus**: Standalone deployment with RBAC-enabled Kubernetes service discovery.
- **Kube State Metrics**: Cluster object visibility (pods, deployments, resources).
- **Node Exporter**: Node-level CPU, memory, and filesystem metrics via DaemonSet.
- **Kubelet Scrapes**: Metrics and cAdvisor data accessed through the API server proxy.
 - **Grafana**: Pre-provisioned Prometheus datasource and the “K8s Views / Global” community dashboard (dotdc/grafana-dashboards-kubernetes).

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
 - Grafana “Global View” dashboard covering node health, namespace/pod counts, resource requests vs. usage, filesystem saturation, network, and controller health across the cluster.

## Notes
- Scrape interval defaults to 15s (`monitoring/k8s/prometheus-config.yaml`).
- Prometheus adds `cluster=demo-cluster` as an external label so dashboards see a cluster name.
- Edit manifests in `monitoring/k8s/` to tweak resources or add dashboards/datasources.
