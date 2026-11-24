"""Article bodies. The JSON Schema is shared with every client (packages/content-schema)."""

import json
import re
from collections.abc import Iterator
from functools import lru_cache
from pathlib import Path
from typing import Any
from uuid import UUID

from jsonschema import Draft202012Validator, validators
from jsonschema.exceptions import ValidationError
from jsonschema.protocols import Validator

from newsplatform.common.errors import DomainError

MAX_BYTES = 900_000
_WPM = 200
EMPTY: dict[str, Any] = {"version": 1, "blocks": []}


def _pattern(validator: Any, pattern: str, instance: Any, schema: Any) -> Iterator[ValidationError]:
    # In Python `$` also matches before a final newline, which JavaScript and Dart refuse.
    if isinstance(instance, str) and not re.search(re.sub(r"\$$", r"\\Z", pattern), instance):
        yield ValidationError("has characters that are not allowed")


def _integer(checker: Any, instance: Any) -> bool:
    return isinstance(instance, int) and not isinstance(instance, bool)


@lru_cache
def _validator() -> Validator:
    schema = json.loads((Path(__file__).parent / "schema" / "content.v1.json").read_text())
    cls: Any = validators.extend(  # type: ignore[no-untyped-call]
        Draft202012Validator,
        {"pattern": _pattern, "oneOf": _one_of},
        type_checker=Draft202012Validator.TYPE_CHECKER.redefine("integer", _integer),
    )
    built: Validator = cls(schema)
    return built


def _one_of(validator: Any, options: list[Any], instance: Any, schema: Any) -> Iterator[ValidationError]:
    """Unions are discriminated by `type`: report what is wrong with that member, not with all of them."""
    kind = instance.get("type") if isinstance(instance, dict) else None
    for option in options:
        resolved = validator._resolver.lookup(option["$ref"]).contents
        spec = resolved["properties"]["type"]
        if isinstance(kind, str) and kind in (spec.get("enum") or [spec.get("const")]):
            yield from validator.descend(instance, option)
            return
    yield ValidationError(f"unknown type {kind!r}")


def validate(document: Any) -> dict[str, Any]:
    if len(json.dumps(document, ensure_ascii=False).encode()) > MAX_BYTES:
        raise DomainError("The article is too long.", code="content_too_large")
    errors = [
        {"field": ".".join(map(str, e.absolute_path)), "message": e.message[:200]}
        for e in _first(_validator().iter_errors(document), 20)
    ]
    if not errors:
        seen: set[str] = set()
        for path, block in walk(document):
            if block["id"] in seen:
                errors.append({"field": f"{path}.id", "message": "duplicate id"})
            seen.add(block["id"])
    if errors:
        raise DomainError("The article body is invalid.", code="invalid_content", errors=errors)
    out: dict[str, Any] = document
    return out


def _first(items: Iterator[ValidationError], limit: int) -> Iterator[ValidationError]:
    for _, item in zip(range(limit), items, strict=False):
        yield item


def walk(document: dict[str, Any]) -> Iterator[tuple[str, dict[str, Any]]]:
    for i, block in enumerate(document["blocks"]):
        yield f"blocks.{i}", block
        if block["type"] == "live_update":
            for j, child in enumerate(block["blocks"]):
                yield f"blocks.{i}.blocks.{j}", child


def asset_ids(document: dict[str, Any]) -> set[UUID]:
    found: set[UUID] = set()
    for _, block in walk(document):
        if block["type"] in ("image", "video"):
            found.add(UUID(block["asset"]))
        elif block["type"] == "gallery":
            found.update(UUID(item["asset"]) for item in block["items"])
    return found


def _texts(value: Any) -> Iterator[str]:
    if isinstance(value, dict):
        for key, child in value.items():
            if key in ("text", "title", "question", "label", "caption", "attribution") and isinstance(
                child, str
            ):
                yield child
            else:
                yield from _texts(child)
    elif isinstance(value, list):
        for child in value:
            yield from _texts(child)


def plain_text(document: dict[str, Any]) -> str:
    return " ".join(_texts(document["blocks"]))


def reading_minutes(document: dict[str, Any]) -> int:
    return max(1, round(len(plain_text(document).split()) / _WPM))
