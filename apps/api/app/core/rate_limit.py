from collections import deque
from math import ceil
from threading import Lock
from time import monotonic

from fastapi import HTTPException, Request


class InMemoryRateLimiter:
    def __init__(self) -> None:
        self._events: dict[str, deque[float]] = {}
        self._lock = Lock()

    def check(self, key: str, *, limit: int, window_seconds: int) -> None:
        now = monotonic()
        window_start = now - window_seconds

        with self._lock:
            events = self._events.setdefault(key, deque())

            while events and events[0] <= window_start:
                events.popleft()

            if len(events) >= limit:
                retry_after = max(1, ceil(events[0] + window_seconds - now))
                raise HTTPException(
                    status_code=429,
                    detail="Too many attempts. Please try again later.",
                    headers={"Retry-After": str(retry_after)},
                )

            events.append(now)

            if len(self._events) > 5000:
                self._remove_empty_buckets(window_start)

    def reset(self, key: str) -> None:
        with self._lock:
            self._events.pop(key, None)

    def clear(self) -> None:
        with self._lock:
            self._events.clear()

    def _remove_empty_buckets(self, window_start: float) -> None:
        stale_keys: list[str] = []

        for key, events in self._events.items():
            while events and events[0] <= window_start:
                events.popleft()

            if not events:
                stale_keys.append(key)

        for key in stale_keys:
            self._events.pop(key, None)


auth_rate_limiter = InMemoryRateLimiter()
api_rate_limiter = InMemoryRateLimiter()


def auth_rate_limit_key(
    request: Request,
    *,
    action: str,
    account: str | None = None,
) -> str:
    client_host = request.client.host if request.client else "unknown"
    normalized_account = account.strip().casefold() if account else "*"

    return f"auth:{action}:{client_host}:{normalized_account}"
