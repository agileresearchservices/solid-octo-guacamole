CLUSTER_NAME ?= demo-cluster
MON_NS ?= monitoring

TARGETS := up down cluster-create cluster-delete deploy-monitoring port-forward-grafana port-forward-prometheus
.PHONY: $(TARGETS)

# One-shot setup: create cluster and deploy monitoring stack
up: cluster-create deploy-monitoring

# Tear down the cluster
down: cluster-delete

# Cluster lifecycle
cluster-create:
	./cluster/create_cluster.sh

cluster-delete:
	./cluster/delete_cluster.sh

# Deploy monitoring stack (Prometheus + exporters + Grafana)
deploy-monitoring:
	./monitoring/deploy.sh

# Port-forward Grafana to localhost:3000
port-forward-grafana:
	kubectl -n $(MON_NS) port-forward svc/grafana 3000:3000

# Port-forward Prometheus to localhost:9090
port-forward-prometheus:
	kubectl -n $(MON_NS) port-forward svc/prometheus 9090:9090
