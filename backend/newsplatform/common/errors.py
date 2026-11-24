"""Domain errors and RFC 9457 problem+json responses. Clients branch on `code`, never on text."""

from typing import Any

import structlog
from django.core.exceptions import PermissionDenied
from django.core.exceptions import ValidationError as ModelValidationError
from django.http import Http404
from rest_framework import exceptions
from rest_framework.response import Response

from newsplatform.common import context

log = structlog.get_logger(__name__)


class DomainError(Exception):
    status: int = 400
    code = "bad_request"

    def __init__(
        self, detail: str = "", *, code: str | None = None, status: int | None = None, **extra: Any
    ) -> None:
        super().__init__(detail)
        self.detail = detail
        self.code = code or self.code
        self.status = status or self.status
        self.extra = extra


class NotFound(DomainError):
    status = 404
    code = "not_found"


class Conflict(DomainError):
    status = 409
    code = "conflict"


class Forbidden(DomainError):
    status = 403
    code = "forbidden"


class StepUpRequired(Forbidden):
    code = "step_up_required"


class RateLimited(DomainError):
    status = 429
    code = "rate_limited"

    def __init__(self, retry_after: int, detail: str = "Too many requests") -> None:
        super().__init__(detail, retry_after=retry_after)
        self.retry_after = retry_after


class ServiceUnavailable(DomainError):
    status = 503
    code = "service_unavailable"


def _problem(status_code: int, code: str, detail: str, **extra: Any) -> Response:
    body = {
        "type": f"urn:newsplatform:error:{code}",
        "title": code.replace("_", " ").capitalize(),
        "status": status_code,
        "code": code,
        "detail": detail,
        "request_id": context.current().request_id,
        **extra,
    }
    response = Response(body, status=status_code, content_type="application/problem+json")
    if "retry_after" in extra:
        response["Retry-After"] = str(extra["retry_after"])
    return response


def _model_errors(exc: ModelValidationError) -> dict[str, list[str]]:
    return exc.message_dict if hasattr(exc, "error_dict") else {"__all__": exc.messages}


def exception_handler(exc: Exception, ctx: dict[str, Any]) -> Response | None:
    if isinstance(exc, DomainError):
        return _problem(exc.status, exc.code, exc.detail, **exc.extra)
    if isinstance(exc, exceptions.ValidationError):
        return _problem(400, "validation_error", "The request is invalid.", errors=exc.detail)
    if isinstance(exc, ModelValidationError):  # from a model's full_clean()
        return _problem(400, "validation_error", "The request is invalid.", errors=_model_errors(exc))
    if isinstance(exc, Http404):
        return _problem(404, "not_found", "Not found.")
    if isinstance(exc, PermissionDenied):
        return _problem(403, "forbidden", "You do not have permission to do this.")
    if isinstance(exc, exceptions.Throttled):
        return _problem(
            429, "rate_limited", "Too many requests", retry_after=int(getattr(exc, "wait", None) or 1)
        )
    if isinstance(exc, exceptions.APIException):
        codes = exc.get_codes()
        response = _problem(exc.status_code, codes if isinstance(codes, str) else "error", str(exc.detail))
        if getattr(exc, "auth_header", None):
            response["WWW-Authenticate"] = exc.auth_header  # type: ignore[attr-defined]
        return response
    log.exception("unhandled_error", view=type(ctx.get("view")).__name__)
    return _problem(500, "internal_error", "Something went wrong.")
