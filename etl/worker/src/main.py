import logging
import os
import random
import time

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

WORK_LOOP_SECONDS = float(os.getenv("WORK_LOOP_SECONDS", "2"))
CPU_BURN_MS = int(os.getenv("CPU_BURN_MS", "150"))
SLEEP_JITTER_MS = int(os.getenv("SLEEP_JITTER_MS", "200"))


def burn_cpu(duration_ms: int) -> None:
    target = time.time() + (duration_ms / 1000.0)
    iterations = 0
    while time.time() < target:
        iterations += 1
        random.random() * random.random()
    logging.debug("CPU burn iterations=%s", iterations)


def main():
    pod_name = os.getenv("POD_NAME", "worker")
    logging.info("Worker %s starting. CPU burn=%sms loop=%ss", pod_name, CPU_BURN_MS, WORK_LOOP_SECONDS)
    while True:
        burn_cpu(CPU_BURN_MS)
        jitter = random.randint(0, SLEEP_JITTER_MS) / 1000.0
        sleep_time = WORK_LOOP_SECONDS + jitter
        logging.info("Worker %s completed cycle; sleeping for %.3fs", pod_name, sleep_time)
        time.sleep(sleep_time)


if __name__ == "__main__":
    main()
