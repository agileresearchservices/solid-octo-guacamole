# Grafana Datasource Configuration Fix

## Problem

When provisioning Grafana dashboards via Kubernetes ConfigMaps, dashboards downloaded from grafana.com may have datasource issues where panels show "No data" or datasource errors.

## Root Cause

Dashboards from grafana.com use template variables for datasources (typically `${datasource}`). When these dashboards are loaded:

1. They contain a `templating.list` section with a datasource variable
2. This variable has a `current` value that might not match your actual datasource
3. The variable needs to reference the datasource by its **uid**, not just its name

## Solution

For each dashboard JSON file, ensure the datasource template variable is correctly configured:

```json
{
  "templating": {
    "list": [
      {
        "name": "datasource",
        "type": "datasource",
        "query": "prometheus",
        "current": {
          "selected": false,
          "text": "Prometheus",
          "value": "prometheus"  // <-- This must match your datasource uid
        }
      }
    ]
  }
}
```

## Fix Commands

Run these commands for each dashboard to properly configure the datasource:

### Step 1: Remove __inputs and fix datasource uid references
```bash
jq 'del(.__inputs) | walk(if type == "object" and has("uid") and .uid == "${DS_PROMETHEUS}" then .uid = "prometheus" else . end)' \
  dashboard.json > dashboard-fixed.json
```

### Step 2: Replace string datasource references
```bash
sed -i '' 's/"datasource": "${DS_PROMETHEUS}"/"datasource": "prometheus"/g' dashboard-fixed.json
```

### Step 3: Update datasource template variable (if present)
```bash
jq '.templating.list |= map(if .name == "datasource" then .current = {"selected": false, "text": "Prometheus", "value": "prometheus"} else . end)' \
  dashboard-fixed.json > dashboard-final.json
```

## Our Configuration

- **Datasource Name**: `Prometheus`
- **Datasource UID**: `prometheus` (defined in monitoring/k8s/grafana-datasource.yaml:11)
- **URL**: `http://prometheus:9090`

## Applied To

This fix has been applied to:
- kubernetes-views-pods.json
- kubernetes-views-nodes.json
- kubernetes-views-namespaces.json
- k8s-cluster-summary.json

## When Adding New Dashboards

Always run the fix command above on any new dashboard downloaded from grafana.com before adding it to the ConfigMap.
