import sys
from pathlib import Path

import pytest

# Ensure the demo app module is importable when running from repo root
ROOT = Path(__file__).resolve().parents[2]
sys.path.append(str(ROOT / "app" / "src"))

import main  # noqa: E402  # isort:skip


def test_burn_cpu_runs_quickly():
    duration = main.burn_cpu(5)
    assert duration > 0


def test_allocate_memory_sets_gauge():
    main.memory_allocated.set(0)
    block = main.allocate_memory(1)
    assert block is not None
    assert main.memory_allocated._value.get() == len(block)


def test_metrics_endpoint_exposes_custom_metrics():
    client = main.app.test_client()
    response = client.get("/metrics")
    assert response.status_code == 200
    body = response.data.decode()
    assert "app_cpu_burn_seconds_total" in body
    assert "app_memory_allocated_bytes" in body
    assert "app_work_cycles_total" in body
