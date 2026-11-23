from typing import Any

from drf_spectacular.extensions import OpenApiAuthenticationExtension


class StaffSessionScheme(OpenApiAuthenticationExtension):  # type: ignore[no-untyped-call]
    target_class = "newsplatform.staff_security.authentication.StaffSessionAuthentication"
    name = "staffSession"

    def get_security_definition(self, auto_schema: Any) -> dict[str, str]:
        from django.conf import settings

        return {"type": "apiKey", "in": "cookie", "name": settings.STAFF_COOKIE_NAME}


def relax_nullable_json(result: Any, generator: Any, request: Any, public: bool) -> Any:
    """`oneOf: [{}, null]` never matches null, as both branches do. Nullable JSON is simply any value."""

    def walk(node: Any) -> None:
        if isinstance(node, dict):
            options = node.get("oneOf")
            if isinstance(options, list) and {} in options:
                del node["oneOf"]
            for child in node.values():
                walk(child)
        elif isinstance(node, list):
            for child in node:
                walk(child)

    walk(result)
    return result
