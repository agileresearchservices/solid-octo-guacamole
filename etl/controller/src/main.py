import logging
import os
import random
import time

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

TASK_INTERVAL = float(os.getenv("TASK_INTERVAL_SECONDS", "5"))
TASK_BATCH_SIZE = int(os.getenv("TASK_BATCH_SIZE", "3"))
WORKER_COUNT = int(os.getenv("WORKER_COUNT", "3"))


def dispatch_tasks():
    task_id = int(time.time())
    for i in range(TASK_BATCH_SIZE):
        target_worker = (task_id + i) % WORKER_COUNT
        payload = random.randint(100000, 200000)
        logging.info("Dispatching task %s.%s -> worker-%s payload=%s", task_id, i, target_worker, payload)


def main():
    logging.info("Controller starting with %s workers, batch size %s, interval %ss", WORKER_COUNT, TASK_BATCH_SIZE, TASK_INTERVAL)
    while True:
        dispatch_tasks()
        time.sleep(TASK_INTERVAL)


if __name__ == "__main__":
    main()
