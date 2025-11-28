CLUSTER_NAME ?= demo-cluster
APP_NAMESPACE ?= demo
MON_NS ?= monitoring
IMAGE_PREFIX ?=
LOAD_IMAGES ?= 1

APP_IMAGE := $(IMAGE_PREFIX)demo-app:local

.PHONY: up down cluster-create cluster-delete build-image load-image deploy-app deploy-monitoring port-forward-grafana port-forward-prometheus test

# One-shot setup: create cluster, build, load, and deploy everything
up: cluster-create build-image load-image deploy-app deploy-monitoring

# Tear down the cluster
down: cluster-delete

# Cluster lifecycle
cluster-create:
	./cluster/create_cluster.sh

cluster-delete:
	./cluster/delete_cluster.sh

# Build demo app image directly in Minikube's Docker
build-image:
	@echo "Building image in Minikube's Docker daemon..."
	@eval $$(minikube -p $(CLUSTER_NAME) docker-env) && docker build -t $(APP_IMAGE) ./app

# Load image into Minikube (not needed when using minikube docker-env, but kept for compatibility)
load-image:
	@echo "Image already in Minikube's Docker (built with minikube docker-env)"

# Deploy demo application
deploy-app:
	./app/deploy.sh

# Deploy monitoring stack (Prometheus + Grafana)
deploy-monitoring:
	./monitoring/deploy.sh

# Port-forward Grafana to localhost:3000
port-forward-grafana:
	kubectl -n $(MON_NS) port-forward svc/grafana 3000:3000

# Port-forward Prometheus to localhost:9090
port-forward-prometheus:
	kubectl -n $(MON_NS) port-forward svc/prometheus 9090:9090

# Port-forward demo app metrics to localhost:8000
port-forward-app:
	kubectl -n $(APP_NAMESPACE) port-forward svc/demo-app 8000:8000

# Syntax check for the Python app
test:
	python -m compileall app
