#!/usr/bin/env bash
set -euo pipefail

# Test script for Kubernetes monitoring stack
# Validates cluster creation, deployment, and component health

CLUSTER_NAME="${CLUSTER_NAME:-demo-cluster}"
MON_NS="${MON_NS:-monitoring}"
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"  # 5 minutes total timeout

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

test_pass() {
  log_info "✓ $1"
  ((TESTS_PASSED++)) || true
}

test_fail() {
  log_error "✗ $1"
  ((TESTS_FAILED++)) || true
}

# Check if command exists
check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    test_pass "$1 is installed"
    return 0
  else
    test_fail "$1 is not installed"
    return 1
  fi
}

# Wait for pod to be ready
wait_for_pod() {
  local selector=$1
  local timeout=${2:-120}
  log_info "Waiting for pod with selector '$selector' (timeout: ${timeout}s)..."
  
  if kubectl -n "${MON_NS}" wait --for=condition=ready pod -l "${selector}" --timeout="${timeout}s" >/dev/null 2>&1; then
    test_pass "Pod with selector '$selector' is ready"
    return 0
  else
    test_fail "Pod with selector '$selector' failed to become ready"
    return 1
  fi
}

# Check if service is accessible
check_service() {
  local service=$1
  local port=$2
  log_info "Checking service ${service} on port ${port}..."
  
  if kubectl -n "${MON_NS}" get svc "${service}" >/dev/null 2>&1; then
    test_pass "Service ${service} exists"
    
    # Check if service has endpoints
    local endpoints=$(kubectl -n "${MON_NS}" get endpoints "${service}" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
    if [ -n "${endpoints}" ]; then
      test_pass "Service ${service} has endpoints"
    else
      test_fail "Service ${service} has no endpoints"
    fi
    return 0
  else
    test_fail "Service ${service} does not exist"
    return 1
  fi
}

# Check Prometheus targets
check_prometheus_targets() {
  log_info "Checking Prometheus targets..."
  
  # Get Prometheus pod name
  local prom_pod=$(kubectl -n "${MON_NS}" get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  
  if [ -z "${prom_pod}" ]; then
    test_fail "Prometheus pod not found"
    return 1
  fi
  
  # Port-forward Prometheus temporarily to check targets
  log_info "Checking Prometheus targets via API..."
  
  # Start port-forward in background
  kubectl -n "${MON_NS}" port-forward "pod/${prom_pod}" 9090:9090 >/dev/null 2>&1 &
  local pf_pid=$!
  sleep 3
  
  # Check if Prometheus is responding
  if curl -s http://localhost:9090/-/healthy >/dev/null 2>&1; then
    test_pass "Prometheus health endpoint is accessible"
    
    # Get targets status
    local targets=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "")
    if [ -n "${targets}" ]; then
      # Count active targets
      local active=$(echo "${targets}" | grep -o '"health":"up"' | wc -l | tr -d ' ')
      if [ "${active}" -gt 0 ]; then
        test_pass "Prometheus has ${active} active target(s)"
      else
        log_warn "Prometheus has no active targets"
      fi
    fi
  else
    test_fail "Prometheus health endpoint is not accessible"
  fi
  
  # Kill port-forward
  kill "${pf_pid}" 2>/dev/null || true
  wait "${pf_pid}" 2>/dev/null || true
}

# Main test execution
main() {
  log_info "Starting tests for Kubernetes monitoring stack..."
  log_info "Cluster: ${CLUSTER_NAME}, Namespace: ${MON_NS}"
  echo ""
  
  # Test 1: Check prerequisites
  log_info "=== Testing Prerequisites ==="
  local prereqs_ok=true
  check_command minikube || prereqs_ok=false
  check_command kubectl || prereqs_ok=false
  check_command docker || prereqs_ok=false
  
  if [ "${prereqs_ok}" = false ]; then
    log_error "Prerequisites check failed. Please install missing tools."
    exit 1
  fi
  echo ""
  
  # Test 2: Check cluster exists
  log_info "=== Testing Cluster ==="
  local cluster_exists=false
  local cluster_running=false
  
  # Try to check cluster status (suppress stderr from minikube profile list)
  if minikube profile list 2>/dev/null | grep -qE "(^| )${CLUSTER_NAME}( |$)" || \
     kubectl config get-contexts -o name 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    cluster_exists=true
    test_pass "Cluster ${CLUSTER_NAME} exists"
    
    # Check if cluster is running by trying to use kubectl
    if kubectl cluster-info --context "${CLUSTER_NAME}" >/dev/null 2>&1; then
      cluster_running=true
      test_pass "Cluster ${CLUSTER_NAME} is running"
    else
      log_warn "Cluster exists but not running, starting..."
      ./cluster/create_cluster.sh || {
        test_fail "Failed to start cluster"
        exit 1
      }
      cluster_running=true
      test_pass "Cluster ${CLUSTER_NAME} started successfully"
    fi
  else
    log_warn "Cluster ${CLUSTER_NAME} does not exist, creating..."
    ./cluster/create_cluster.sh || {
      test_fail "Failed to create cluster"
      exit 1
    }
    cluster_exists=true
    cluster_running=true
    test_pass "Cluster ${CLUSTER_NAME} created successfully"
  fi
  
  # Set kubectl context
  kubectl config use-context "${CLUSTER_NAME}" >/dev/null 2>&1 || true
  echo ""
  
  # Test 3: Check namespace
  log_info "=== Testing Namespace ==="
  if kubectl get ns "${MON_NS}" >/dev/null 2>&1; then
    test_pass "Namespace ${MON_NS} exists"
  else
    test_fail "Namespace ${MON_NS} does not exist"
    log_warn "Creating namespace..."
    kubectl create namespace "${MON_NS}" || {
      test_fail "Failed to create namespace"
      exit 1
    }
  fi
  echo ""
  
  # Test 4: Deploy monitoring stack if not deployed
  log_info "=== Testing Monitoring Deployment ==="
  local prom_deployed=false
  if kubectl -n "${MON_NS}" get deployment prometheus >/dev/null 2>&1; then
    test_pass "Prometheus deployment exists"
    prom_deployed=true
  else
    test_fail "Prometheus deployment not found"
    log_warn "Deploying monitoring stack..."
    ./monitoring/deploy.sh || {
      test_fail "Failed to deploy monitoring stack"
      exit 1
    }
    prom_deployed=true
  fi
  
  if [ "${prom_deployed}" = true ]; then
    # Wait a bit for deployments to stabilize
    sleep 5
  fi
  echo ""
  
  # Test 5: Check pod readiness
  log_info "=== Testing Pod Readiness ==="
  wait_for_pod "app=prometheus" 120
  wait_for_pod "app=grafana" 120
  wait_for_pod "app=kube-state-metrics" 120
  wait_for_pod "app=node-exporter" 120
  echo ""
  
  # Test 6: Check services
  log_info "=== Testing Services ==="
  check_service "prometheus" "9090"
  check_service "grafana" "3000"
  check_service "kube-state-metrics" "8080"
  echo ""
  
  # Test 7: Check Prometheus targets
  log_info "=== Testing Prometheus Targets ==="
  check_prometheus_targets
  echo ""
  
  # Test 8: Verify Grafana datasource
  log_info "=== Testing Grafana Configuration ==="
  local grafana_pod=$(kubectl -n "${MON_NS}" get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -n "${grafana_pod}" ]; then
    # Check if datasource configmap exists
    if kubectl -n "${MON_NS}" get configmap grafana-datasource >/dev/null 2>&1; then
      test_pass "Grafana datasource ConfigMap exists"
    else
      test_fail "Grafana datasource ConfigMap not found"
    fi
    
    # Check if dashboard configmap exists
    if kubectl -n "${MON_NS}" get configmap grafana-dashboards >/dev/null 2>&1; then
      test_pass "Grafana dashboard ConfigMap exists"
    else
      test_fail "Grafana dashboard ConfigMap not found"
    fi
  else
    test_fail "Grafana pod not found"
  fi
  echo ""
  
  # Test 9: Check resource usage
  log_info "=== Testing Resource Status ==="
  local pods_ready=$(kubectl -n "${MON_NS}" get pods --no-headers 2>/dev/null | grep -c "Running\|Completed" || echo "0")
  local pods_total=$(kubectl -n "${MON_NS}" get pods --no-headers 2>/dev/null | wc -l | tr -d ' ')
  
  if [ "${pods_total}" -gt 0 ]; then
    test_pass "Found ${pods_total} pod(s) in namespace"
    if [ "${pods_ready}" -eq "${pods_total}" ]; then
      test_pass "All pods are in ready state"
    else
      log_warn "${pods_ready}/${pods_total} pods are ready"
    fi
  else
    test_fail "No pods found in namespace"
  fi
  echo ""
  
  # Summary
  log_info "=== Test Summary ==="
  log_info "Tests passed: ${TESTS_PASSED}"
  if [ "${TESTS_FAILED}" -gt 0 ]; then
    log_error "Tests failed: ${TESTS_FAILED}"
    exit 1
  else
    log_info "All tests passed! ✓"
    exit 0
  fi
}

# Run main function
main "$@"

