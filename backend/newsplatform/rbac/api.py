from typing import Any, ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.accounts.models import User
from newsplatform.common.api import StaffView, schema
from newsplatform.common.errors import NotFound
from newsplatform.rbac import selectors, services
from newsplatform.rbac.models import Role, RoleAssignment
from newsplatform.rbac.registry import PERMISSIONS
from newsplatform.staff_security.authentication import session_of


class RoleSerializer(serializers.ModelSerializer[Role]):
    members = serializers.IntegerField(read_only=True, default=0)
    permissions = serializers.ListField(child=serializers.CharField())

    class Meta:
        model = Role
        fields = [
            "id",
            "key",
            "name_en",
            "name_sw",
            "description",
            "permissions",
            "is_system",
            "is_staff",
            "is_privileged",
            "members",
        ]


class RoleWriteSerializer(serializers.Serializer[Any]):
    key = serializers.SlugField(max_length=48, required=False, default="")
    name_en = serializers.CharField(max_length=80)
    name_sw = serializers.CharField(max_length=80)
    description = serializers.CharField(max_length=300, allow_blank=True, default="")
    permissions = serializers.ListField(child=serializers.CharField(max_length=64), max_length=200)


class PermissionSerializer(serializers.Serializer[Any]):
    code = serializers.CharField()
    en = serializers.CharField()
    sw = serializers.CharField()
    scopable = serializers.BooleanField()
    sensitive = serializers.BooleanField()


def _role(role_id: Any) -> Role:
    role = Role.objects.filter(pk=role_id).first()
    if role is None:
        raise NotFound("Not found")
    return role


class RoleListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "staff.view", "POST": "roles.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(
        operation_id="roles_list",
        responses=schema(
            "RoleList", roles=RoleSerializer(many=True), permissions=PermissionSerializer(many=True)
        ),
    )
    def get(self, request: Request) -> Response:
        from django.db.models import Count

        rows = selectors.roles().annotate(members=Count("assignments"))
        return Response(
            {
                "roles": RoleSerializer(rows, many=True).data,
                "permissions": PermissionSerializer(list(PERMISSIONS.values()), many=True).data,
            }
        )

    @extend_schema(operation_id="roles_create", request=RoleWriteSerializer, responses={201: RoleSerializer})
    def post(self, request: Request) -> Response:
        data = RoleWriteSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        if not data.validated_data["key"]:
            raise serializers.ValidationError({"key": ["Required"]})
        role = services.save_role(actor=session_of(request).user, role=None, **data.validated_data)
        return Response(RoleSerializer(role).data, status=201)


class RoleItemView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"PUT": "roles.manage", "DELETE": "roles.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("PUT", "DELETE")

    @extend_schema(operation_id="roles_update", request=RoleWriteSerializer, responses=RoleSerializer)
    def put(self, request: Request, role_id: Any) -> Response:
        data = RoleWriteSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        role = services.save_role(actor=session_of(request).user, role=_role(role_id), **data.validated_data)
        return Response(RoleSerializer(role).data)

    @extend_schema(operation_id="roles_delete", responses={204: None})
    def delete(self, request: Request, role_id: Any) -> Response:
        services.delete_role(actor=session_of(request).user, role=_role(role_id))
        return Response(status=204)


class AssignmentListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "staff.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    class AssignmentCreate(serializers.Serializer[Any]):
        user = serializers.UUIDField()
        role = serializers.SlugField()
        scope_type = serializers.CharField(default="", allow_blank=True)
        scope_id = serializers.CharField(default="", allow_blank=True)

    @extend_schema(
        operation_id="assignments_create",
        request=AssignmentCreate,
        responses={201: schema("AssignmentResult", approval_required=serializers.BooleanField())},
    )
    def post(self, request: Request) -> Response:
        from newsplatform.staff_security.staff import grant_role

        data = self.AssignmentCreate(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        user = User.objects.filter(pk=d["user"], is_staff_member=True).first()
        role = Role.objects.filter(key=d["role"]).first()
        if user is None or role is None:
            raise NotFound("Not found")
        result = grant_role(
            actor=session_of(request).user,
            user=user,
            role=role,
            scope_type=d["scope_type"],
            scope_id=d["scope_id"],
        )
        return Response({"approval_required": not isinstance(result, RoleAssignment)}, status=201)


class AssignmentItemView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"DELETE": "staff.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("DELETE",)

    @extend_schema(operation_id="assignments_delete", responses={204: None})
    def delete(self, request: Request, assignment_id: Any) -> Response:
        row = RoleAssignment.objects.select_related("role", "user").filter(pk=assignment_id).first()
        if row is None:
            raise NotFound("Not found")
        services.revoke_assignment(actor=session_of(request).user, assignment=row)
        return Response(status=204)
