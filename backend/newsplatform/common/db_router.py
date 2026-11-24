"""Reads go to the replica only inside `use_replica()`: stale reads are always opt-in."""

from collections.abc import Iterator
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Any

from django.conf import settings
from django.db import transaction

_replica: ContextVar[bool] = ContextVar("use_replica", default=False)


@contextmanager
def use_replica() -> Iterator[None]:
    token = _replica.set(True)
    try:
        yield
    finally:
        _replica.reset(token)


class ReplicaRouter:
    def db_for_read(self, model: Any, **hints: Any) -> str | None:
        wants = _replica.get() and "replica" in settings.DATABASES
        return "replica" if wants and not transaction.get_connection().in_atomic_block else "default"

    def db_for_write(self, model: Any, **hints: Any) -> str:
        return "default"

    def allow_relation(self, *_: Any, **__: Any) -> bool:
        return True

    def allow_migrate(self, db: str, *_: Any, **__: Any) -> bool:
        return db == "default"
