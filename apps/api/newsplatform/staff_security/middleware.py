from collections.abc import Callable

from django.http import HttpRequest, HttpResponse, JsonResponse

from newsplatform.common import context
from newsplatform.site_config.services import get_security, ip_allowed


class IpAllowlistMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        if not request.path.startswith("/health/") and not ip_allowed(context.current().ip, get_security()):
            return JsonResponse(
                {
                    "type": "urn:newsplatform:error:ip_not_allowed",
                    "title": "Ip not allowed",
                    "status": 403,
                    "code": "ip_not_allowed",
                    "detail": "Access is restricted.",
                },
                status=403,
                content_type="application/problem+json",
            )
        return self.get_response(request)
