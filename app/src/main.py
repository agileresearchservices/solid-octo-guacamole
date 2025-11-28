import logging
import os
import random
import time
from threading import Thread
from flask import Flask, Response
from prometheus_client import Counter, Gauge, Histogram, generate_latest, REGISTRY

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# Prometheus metrics
cpu_burn_total = Counter('app_cpu_burn_seconds_total', 'Total CPU burn time in seconds')
memory_allocated = Gauge('app_memory_allocated_bytes', 'Current memory allocation in bytes')
work_cycles_total = Counter('app_work_cycles_total', 'Total number of work cycles completed')
cycle_duration = Histogram('app_cycle_duration_seconds', 'Work cycle duration in seconds')

# Configuration from environment
WORK_LOOP_SECONDS = float(os.getenv("WORK_LOOP_SECONDS", "5"))
CPU_BURN_MS = int(os.getenv("CPU_BURN_MS", "200"))
MEMORY_ALLOC_MB = int(os.getenv("MEMORY_ALLOC_MB", "50"))

# Flask app for /metrics endpoint
app = Flask(__name__)

@app.route('/metrics')
def metrics():
    data = generate_latest(REGISTRY)
    response = Response(data)
    response.headers['Content-Type'] = 'text/plain; version=0.0.4; charset=utf-8'
    return response

@app.route('/health')
def health():
    return 'OK', 200

def burn_cpu(duration_ms: int) -> float:
    """Burn CPU for specified milliseconds and return actual time spent"""
    start = time.time()
    target = start + (duration_ms / 1000.0)
    iterations = 0
    while time.time() < target:
        iterations += 1
        _ = random.random() * random.random()
    actual_time = time.time() - start
    logging.debug(f"CPU burn iterations={iterations}, actual_time={actual_time:.3f}s")
    return actual_time

def allocate_memory(size_mb: int):
    """Allocate specified amount of memory"""
    try:
        # Create a bytearray to allocate memory
        data = bytearray(size_mb * 1024 * 1024)
        # Write to it to ensure it's actually allocated
        for i in range(0, len(data), 4096):
            data[i] = random.randint(0, 255)
        memory_allocated.set(len(data))
        return data
    except MemoryError:
        logging.error(f"Failed to allocate {size_mb}MB of memory")
        return None

def worker_loop():
    """Main worker loop that simulates resource usage"""
    pod_name = os.getenv("POD_NAME", "demo-app")
    logging.info(f"Worker {pod_name} starting. CPU burn={CPU_BURN_MS}ms, memory={MEMORY_ALLOC_MB}MB, loop={WORK_LOOP_SECONDS}s")

    # Keep reference to allocated memory to prevent GC and keep gauge stable
    memory_block = allocate_memory(MEMORY_ALLOC_MB)

    while True:
        cycle_start = time.time()

        # Burn CPU and track time
        burn_time = burn_cpu(CPU_BURN_MS)
        cpu_burn_total.inc(burn_time)

        # Ensure memory remains allocated; top up if GC cleaned it up
        if memory_block is None:
            memory_block = allocate_memory(MEMORY_ALLOC_MB)
        else:
            memory_allocated.set(len(memory_block))

        # Increment work cycles counter
        work_cycles_total.inc()

        # Record cycle duration
        cycle_time = time.time() - cycle_start
        cycle_duration.observe(cycle_time)

        logging.info(f"Worker {pod_name} completed cycle: burn_time={burn_time:.3f}s, cycle_time={cycle_time:.3f}s")

        # Sleep before next cycle
        time.sleep(WORK_LOOP_SECONDS)

def main():
    # Start worker loop in background thread
    worker_thread = Thread(target=worker_loop, daemon=True)
    worker_thread.start()

    # Start Flask server for /metrics endpoint
    port = int(os.getenv("PORT", "8000"))
    logging.info(f"Starting metrics server on port {port}")
    app.run(host='0.0.0.0', port=port)

if __name__ == "__main__":
    main()
