import time
import uuid


class JobLogger:

    def __init__(self):
        self.request_id = str(uuid.uuid4())[:8]

    def start_provider(self, name: str):
        print(f"\n[{self.request_id}] ▶ {name}")

    def success(self, name: str, count: int, elapsed: float):
        print(f"[{self.request_id}] ✔ {name}: {count} jobs ({elapsed:.2f}s)")

    def error(self, name: str, error: Exception):
        print(f"[{self.request_id}] ✖ {name}: {error}")