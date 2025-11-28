CLUSTER_NAME ?= etl-demo
ETL_NAMESPACE ?= etl-demo
MON_NS ?= monitoring
IMAGE_PREFIX ?=
LOAD_WITH_KIND ?= 1
SKIP_CLUSTER_CREATE ?= 0

CONTROLLER_IMAGE := $(IMAGE_PREFIX)etl-controller:local
WORKER_IMAGE := $(IMAGE_PREFIX)etl-worker:local

.PHONY: up down cluster-create cluster-delete build-images load-images deploy-monitoring deploy-etl port-forward-grafana
.PHONY: test

up: cluster-create build-images load-images deploy-monitoring deploy-etl

up-existing: build-images load-images deploy-monitoring deploy-etl

down: cluster-delete

cluster-create:
	./cluster/create_cluster.sh

cluster-delete:
	./cluster/delete_cluster.sh

build-images:
	docker build -t $(CONTROLLER_IMAGE) ./etl/controller
	docker build -t $(WORKER_IMAGE) ./etl/worker

load-images:
ifeq ($(LOAD_WITH_KIND),1)
	kind load docker-image $(CONTROLLER_IMAGE) --name $(CLUSTER_NAME)
	kind load docker-image $(WORKER_IMAGE) --name $(CLUSTER_NAME)
else
	@echo "Skipping kind image load. Ensure $(CONTROLLER_IMAGE) and $(WORKER_IMAGE) are reachable by your cluster (push to a registry if needed)."
endif

deploy-monitoring:
	./monitoring/deploy_monitoring.sh

deploy-etl:
	IMAGE_PREFIX=$(IMAGE_PREFIX) ./etl/deploy_etl.sh

port-forward-grafana:
	kubectl -n $(MON_NS) port-forward svc/kube-prometheus-grafana 3000:80

# Lightweight syntax check for the Python ETL components
test:
	python -m compileall etl
