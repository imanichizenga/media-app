"""Structured JSON logs with PII and secrets redacted at the logger, not at call sites."""

import logging
import re
from collections.abc import MutableMapping
from typing import Any

import structlog

from newsplatform.common import context

REDACTED = "[redacted]"
_SENSITIVE_KEY = re.compile(
    r"pass(word|wd|phrase)?$|secret|token|otp|authorization|cookie|api[_-]?key|private[_-]?key|credential"
    r"|csrf|recovery|totp|signature|session_key|access_key|phone|email|msisdn",
    re.I,
)
_EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
_PHONE = re.compile(r"(?<![\w-])\+\d{8,15}(?!\w)")
_AWS_KEY = re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b")
_JWT = re.compile(r"\beyJ[\w-]{8,}\.[\w-]{8,}\.[\w-]*")
_BEARER = re.compile(r"(?i)\bbearer\s+\S+")


def redact_text(text: str) -> str:
    for pattern in (_EMAIL, _PHONE, _AWS_KEY, _JWT, _BEARER):
        text = pattern.sub(REDACTED, text)
    return text


def redact(value: Any, depth: int = 0) -> Any:
    if depth > 8:
        return "[truncated]"
    if isinstance(value, dict):
        return {
            k: REDACTED if _SENSITIVE_KEY.search(str(k)) else redact(v, depth + 1) for k, v in value.items()
        }
    if isinstance(value, list | tuple):
        return [redact(v, depth + 1) for v in value]
    if isinstance(value, bytes):
        return f"[{len(value)} bytes]"
    return redact_text(value) if isinstance(value, str) else value


def _redactor(_: Any, __: str, event: MutableMapping[str, Any]) -> MutableMapping[str, Any]:
    return {
        k: v
        if k in {"event", "level", "timestamp", "logger"} and not isinstance(v, str)
        else redact({k: v})[k]
        for k, v in event.items()
    }


def _correlate(_: Any, __: str, event: MutableMapping[str, Any]) -> MutableMapping[str, Any]:
    ctx = context.current()
    if ctx.request_id:
        event.setdefault("request_id", ctx.request_id)
    try:
        from opentelemetry import trace

        span = trace.get_current_span().get_span_context()
        if span.is_valid:
            event.setdefault("trace_id", format(span.trace_id, "032x"))
    except ImportError:
        pass
    return event


def configure(level: str = "INFO", *, json: bool = True) -> None:
    shared: list[Any] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.stdlib.PositionalArgumentsFormatter(),
        _correlate,
    ]
    structlog.configure(
        processors=[*shared, structlog.stdlib.ProcessorFormatter.wrap_for_formatter],
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=False,
    )
    renderer: Any = structlog.processors.JSONRenderer() if json else structlog.dev.ConsoleRenderer()
    handler = logging.StreamHandler()
    # format_exc_info runs before the redactor so tracebacks are scrubbed too.
    handler.setFormatter(
        structlog.stdlib.ProcessorFormatter(
            foreign_pre_chain=[*shared, structlog.stdlib.ExtraAdder()],
            processors=[
                structlog.stdlib.ProcessorFormatter.remove_processors_meta,
                structlog.processors.format_exc_info,
                _redactor,
                renderer,
            ],
        )
    )
    root = logging.getLogger()
    root.handlers[:] = [handler]
    root.setLevel(level)
