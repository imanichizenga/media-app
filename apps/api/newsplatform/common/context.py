"""Per-request context, available to services, logs, audit and Celery tasks."""

from contextvars import ContextVar
from dataclasses import dataclass, replace


@dataclass(frozen=True, slots=True)
class RequestContext:
    request_id: str = ""
    ip: str | None = None
    user_agent: str = ""
    country: str = ""


_ctx: ContextVar[RequestContext | None] = ContextVar("request_context", default=None)


def current() -> RequestContext:
    return _ctx.get() or RequestContext()


def set_context(ctx: RequestContext | None) -> None:
    _ctx.set(ctx)


def update(**changes: str | None) -> None:
    _ctx.set(replace(current(), **changes))  # type: ignore[arg-type]
