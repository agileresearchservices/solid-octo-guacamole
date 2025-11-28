# Minimal Kubernetes Monitoring Demo: Prometheus + Grafana

This repo contains a fully reproducible local demo that provisions a Minikube cluster with a minimal monitoring stack. It demonstrates the simplest possible setup for Prometheus and Grafana in Kubernetes, perfect for learning and understanding the fundamentals.

## Architecture

**Ultra-minimal: Just 3 pods**

```
┌─────────────────┐
│  Demo App       │ ← Exposes custom metrics on /metrics
│  (1 pod)        │    (CPU burn, memory, work cycles)
└─────────────────┘
         ↑
         │ scrapes every 15s
         │
┌─────────────────┐
│  Prometheus     │ ← Standalone deployment (no operator)
│  (1 pod)        │
└─────────────────┘
         ↑
         │ queries
         │
┌─────────────────┐
│  Grafana        │ ← Pre-configured dashboard
│  (1 pod)        │
└─────────────────┘
```

## Why This Approach?

- **Educational**: Every component is visible and understandable
- **Minimal**: No Helm, no operators, no CRDs - just plain YAML
- **Fast**: Deploys in ~30 seconds
- **Standard**: Uses common Prometheus patterns (static scraping)
- **Portable**: Works on any Kubernetes cluster

## Repository Layout

```
app/                         # Demo application
  src/main.py                # Python app with Prometheus metrics
  Dockerfile
  requirements.txt
  k8s/
    namespace.yaml
    deployment.yaml          # App deployment + service
  deploy.sh
cluster/                     # Minikube cluster lifecycle
  create_cluster.sh
  delete_cluster.sh
monitoring/                  # Monitoring stack
  k8s/
    prometheus-config.yaml   # Prometheus scrape config
    prometheus.yaml          # Prometheus deployment + PVC
    grafana-datasource.yaml  # Grafana datasource config
    grafana-dashboard.yaml   # Pre-loaded dashboard
    grafana.yaml             # Grafana deployment
  deploy.sh
Makefile                     # Convenience targets
README.md
```

## Prerequisites

- Docker
- `kubectl`
- `minikube`
- Python 3 (for optional syntax checking)

## Quick Start

```bash
# 1) Create Minikube cluster (single node)
make cluster-create

# 2) Build and load demo app image
make build-image
make load-image

# 3) Deploy demo application
make deploy-app

# 4) Deploy monitoring stack (Prometheus + Grafana)
make deploy-monitoring

# 5) Access Grafana
make port-forward-grafana
# Visit http://localhost:3000
# Login: admin / admin
# Dashboard: "Demo App Metrics"
```

**Or use the one-shot command:**
```bash
make up
```

## What the Demo App Does

The demo application:
- Runs a continuous loop that burns CPU and allocates memory
- Exposes Prometheus metrics on `/metrics` endpoint (port 8000)
- Provides custom metrics:
  - `app_cpu_burn_seconds_total` - Total CPU burn time
  - `app_memory_allocated_bytes` - Current memory allocation
  - `app_work_cycles_total` - Number of cycles completed
  - `app_cycle_duration_seconds` - Histogram of cycle durations

## Accessing the Components

**Grafana:**
```bash
make port-forward-grafana
# Visit: http://localhost:3000
# Login: admin / admin
```

**Prometheus:**
```bash
make port-forward-prometheus
# Visit: http://localhost:9090
# Check targets: http://localhost:9090/targets
```

**Demo App Metrics:**
```bash
make port-forward-app
# Visit: http://localhost:8000/metrics
```

## Dashboard Panels

The pre-loaded Grafana dashboard shows:
1. **CPU Burn Rate** - Rate of CPU burn time over time
2. **Memory Allocated** - Current memory allocation (gauge)
3. **Work Cycles Rate** - Work cycles per second
4. **Cycle Duration Percentiles** - p50, p95, p99 latencies

## Tear Down

```bash
make down
```

This removes the Minikube cluster entirely. To redeploy, run `make up` again.

## Customization

### Adjust Demo App Workload

Edit `app/k8s/deployment.yaml` environment variables:
- `WORK_LOOP_SECONDS` - Time between cycles (default: 5)
- `CPU_BURN_MS` - CPU burn duration per cycle (default: 200)
- `MEMORY_ALLOC_MB` - Memory to allocate (default: 50)

### Adjust Prometheus Scrape Interval

Edit `monitoring/k8s/prometheus-config.yaml`:
```yaml
global:
  scrape_interval: 15s  # Change this
```

### Modify Dashboard

The dashboard JSON is in `monitoring/k8s/grafana-dashboard.yaml`. Edit the `demo-dashboard.json` section to add new panels or modify queries.

## How It Works

### Prometheus Scraping

Prometheus uses a simple static configuration to scrape the demo app:

```yaml
scrape_configs:
  - job_name: 'demo-app'
    static_configs:
      - targets: ['demo-app.demo.svc.cluster.local:8000']
```

No service discovery, no annotations needed - just a direct target.

### Grafana Provisioning

Grafana is configured with:
1. **Datasource provisioning** - Automatically connects to Prometheus
2. **Dashboard provisioning** - Automatically loads the demo dashboard

Both are ConfigMaps mounted into the Grafana pod.

### Persistence

Prometheus uses a PersistentVolumeClaim (5Gi) to retain metrics across pod restarts. Data retention is set to 24 hours.

## Troubleshooting

**Prometheus shows no targets:**
- Check if demo app is running: `kubectl -n demo get pods`
- Check Prometheus logs: `kubectl -n monitoring logs -l app=prometheus`

**Grafana dashboard shows "No data":**
- Wait 30 seconds for metrics to be scraped
- Check Prometheus has data: Visit http://localhost:9090 and query `app_work_cycles_total`

**Images not found:**
- Rerun `make load-image` to ensure image is in Minikube

## Comparison to kube-prometheus-stack

This demo intentionally avoids the complexity of production monitoring stacks:

| Feature | This Demo | kube-prometheus-stack |
|---------|-----------|----------------------|
| Pods | 3 | 10+ |
| Helm | No | Yes |
| Operator | No | Yes |
| CRDs | No | Yes (ServiceMonitor, PodMonitor, etc.) |
| Setup time | ~30s | ~3min |
| Good for | Learning, demos | Production |

## Learning Path

This demo is designed for learning. Once you understand these basics, you can explore:
1. **Service discovery** - Instead of static configs
2. **Prometheus Operator** - For dynamic configuration
3. **AlertManager** - For alerting on metrics
4. **Long-term storage** - Remote write to systems like Thanos or Cortex

## Sources

Based on research and best practices from:
- [Prometheus Operator vs Standalone](https://stackoverflow.com/questions/54771126/what-is-the-best-practice-for-deploying-prometheus-monitoring-kubernetes)
- [Simple Prometheus Demo](https://blog.purestorage.com/purely-technical/introductory-monitoring-stack-with-prometheus-and-grafana/)
- [Annotation-based Scraping](https://betterstack.com/community/questions/monitor-custom-kubernetes-pod-metrics-using-prometheus/)
- [Prometheus Pod Monitoring](https://signoz.io/guides/how-to-monitor-custom-kubernetes-pod-metrics-using-prometheus/)
