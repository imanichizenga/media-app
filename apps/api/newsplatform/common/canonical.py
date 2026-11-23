"""Deterministic JSON. Floats are rejected: they do not round-trip through JSONB byte-for-byte."""

import datetime as dt
import decimal
import enum
import json
import uuid
from typing import Any


def to_plain(value: Any) -> Any:
    if value is None or isinstance(value, bool | int):
        return value
    if isinstance(value, enum.Enum):
        return to_plain(value.value)
    if isinstance(value, str):
        # JSONB cannot store U+0000.
        return value.replace("\x00", "�")
    if isinstance(value, float | decimal.Decimal | uuid.UUID):
        return str(value)
    if isinstance(value, dt.datetime):
        return value.astimezone(dt.UTC).isoformat(timespec="microseconds")
    if isinstance(value, dt.date):
        return value.isoformat()
    if isinstance(value, dict):
        return {to_plain(str(k)): to_plain(v) for k, v in value.items()}
    if isinstance(value, list | tuple | set | frozenset):
        items = sorted(value, key=str) if isinstance(value, set | frozenset) else value
        return [to_plain(v) for v in items]
    raise TypeError(f"Cannot canonicalise {type(value).__name__}")


def canonical_json(value: Any) -> bytes:
    return json.dumps(
        to_plain(value), sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False
    ).encode()
