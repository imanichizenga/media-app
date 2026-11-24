"""Shared base for admin endpoints: staff permission, per-user throttle, schema helpers."""

from typing import Any, ClassVar

from drf_spectacular.utils import inline_serializer
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.views import APIView

from newsplatform.common import context
from newsplatform.common.ratelimit import Limit, check, subject_key
from newsplatform.rbac.permissions import PublicEndpoint, StaffPermission
from newsplatform.staff_security.authentication import check_origin


class _Scoped(APIView):
    limit: ClassVar[Limit]

    def _limit_scope(self) -> str:
        """Views on the default limit share one budget; a view with its own limit gets its own."""
        return type(self).__name__ if "limit" in type(self).__dict__ else "default"


class StaffView(_Scoped):
    permission_classes = [StaffPermission]
    perms: ClassVar[dict[str, str | None]] = {}
    step_up: ClassVar[tuple[str, ...]] = ()
    limit: ClassVar[Limit] = Limit(240, 60)

    def check_throttles(self, request: Request) -> None:
        check(f"admin:{self._limit_scope()}", str(request.user.pk), self.limit, fail_closed=False)


class AnonymousStaffView(_Scoped):
    """Before sign-in: strict per-IP limit that fails closed, plus an Origin check."""

    authentication_classes = []
    permission_classes = [PublicEndpoint]
    limit: ClassVar[Limit] = Limit(30, 60)

    def initial(self, request: Request, *args: Any, **kwargs: Any) -> None:
        check_origin(request)
        super().initial(request, *args, **kwargs)

    def check_throttles(self, request: Request) -> None:
        check(
            f"anon:{self._limit_scope()}",
            subject_key(context.current().ip or "-"),
            self.limit,
            fail_closed=True,
        )


def schema(name: str, /, **fields: serializers.Field[Any, Any, Any, Any]) -> Any:
    return inline_serializer(name=name, fields=fields)


class ProblemSerializer(serializers.Serializer[Any]):
    type = serializers.CharField()
    title = serializers.CharField()
    status = serializers.IntegerField()
    code = serializers.CharField()
    detail = serializers.CharField()
    request_id = serializers.CharField()


class PersonSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    display_name = serializers.CharField()


def body(request: Request) -> dict[str, Any]:
    if not isinstance(request.data, dict):
        raise serializers.ValidationError("Expected a JSON object")
    return request.data
