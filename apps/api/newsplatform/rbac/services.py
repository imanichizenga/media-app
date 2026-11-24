from datetime import datetime

from django.db import transaction
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError, Forbidden
from newsplatform.rbac import selectors
from newsplatform.rbac.models import Role, RoleAssignment
from newsplatform.rbac.registry import PERMISSIONS, SYSTEM_ROLES, scope_exists, scope_types


def sync_system_roles() -> None:
    """Create missing system roles. super_admin always tracks the full catalogue; others stay DB-edited."""
    for spec in SYSTEM_ROLES:
        role, _ = Role.objects.get_or_create(
            key=spec.key,
            defaults={
                "name_en": spec.en,
                "name_sw": spec.sw,
                "permissions": sorted(spec.permissions),
                "is_system": True,
                "is_staff": spec.staff,
                "is_privileged": spec.privileged,
            },
        )
        if spec.key == "super_admin" and set(role.permissions) != set(PERMISSIONS):
            role.permissions = sorted(PERMISSIONS)
            role.save(update_fields=["permissions", "updated_at"])


def _check_permissions(actor: User, wanted: set[str]) -> None:
    if unknown := wanted - PERMISSIONS.keys():
        raise DomainError("Unknown permissions", code="unknown_permission", permissions=sorted(unknown))
    if excess := wanted - selectors.grants_for(actor).everywhere:
        raise Forbidden(
            "You cannot grant permissions you do not hold.",
            code="privilege_escalation",
            permissions=sorted(excess),
        )


@transaction.atomic
def save_role(
    *,
    actor: User,
    role: Role | None,
    key: str = "",
    name_en: str,
    name_sw: str,
    description: str,
    permissions: list[str],
) -> Role:
    selectors.require(actor, "roles.manage")
    wanted = set(permissions)
    before = None
    if role is None:
        _check_permissions(actor, wanted)
        if Role.objects.filter(key=key).exists():
            raise Conflict("A role with this key already exists.", code="role_exists")
        role = Role(key=key)
    else:
        role = Role.objects.select_for_update().get(pk=role.pk)
        if role.key == "super_admin":
            raise Forbidden("The Super Admin role cannot be edited.", code="system_role")
        # Both additions and removals are limited to what the actor holds.
        _check_permissions(actor, wanted ^ set(role.permissions))
        if RoleAssignment.objects.filter(role=role, user=actor).exists():
            raise Forbidden("You cannot edit a role you hold.", code="self_modification")
        before = selectors.snapshot(role)
    role.name_en, role.name_sw, role.description = name_en, name_sw, description
    role.permissions = sorted(wanted)
    role.save()
    record(
        actor=actor,
        action="role.updated" if before else "role.created",
        target=role,
        label=role.key,
        before=before,
        after=selectors.snapshot(role),
    )
    return role


@transaction.atomic
def delete_role(*, actor: User, role: Role) -> None:
    selectors.require(actor, "roles.manage")
    if role.is_system:
        raise Forbidden("System roles cannot be deleted.", code="system_role")
    _check_permissions(actor, set(role.permissions))
    if role.assignments.exists():
        raise Conflict("Remove this role from everyone first.", code="role_in_use")
    record(actor=actor, action="role.deleted", target=role, label=role.key, before=selectors.snapshot(role))
    role.delete()


def check_can_grant(
    *, actor: User, target: User | None, role: Role, scope_type: str = "", scope_id: str = ""
) -> None:
    selectors.require(actor, "staff.manage" if target else "staff.invite")
    if target and target.pk == actor.pk:
        raise Forbidden("You cannot change your own roles.", code="self_modification")
    if scope_type and scope_type not in scope_types():
        raise DomainError("Unknown scope", code="unknown_scope")
    if scope_type and not scope_exists(scope_type, scope_id):
        raise DomainError("This scope does not exist.", code="unknown_scope")
    _check_permissions(actor, set(role.permissions))


@transaction.atomic
def assign_role(
    *,
    actor: User | None,
    user: User,
    role: Role,
    scope_type: str = "",
    scope_id: str = "",
    expires_at: datetime | None = None,
    approved_by: User | None = None,
) -> RoleAssignment:
    """`actor=None` is reserved for bootstrap. Approval policy is enforced by the caller (approvals app)."""
    if actor:
        check_can_grant(actor=actor, target=user, role=role, scope_type=scope_type, scope_id=scope_id)
    if expires_at and expires_at <= timezone.now():
        raise DomainError("Expiry must be in the future", code="invalid_expiry")
    assignment, _ = RoleAssignment.objects.update_or_create(
        user=user,
        role=role,
        scope_type=scope_type,
        scope_id=scope_id,
        defaults={"granted_by": actor, "expires_at": expires_at},
    )
    if role.is_staff and not user.is_staff_member:
        user.is_staff_member = True
        user.save(update_fields=["is_staff_member", "updated_at"])
    record(
        actor=actor,
        action="role.assigned",
        target=user,
        label=user.display_name,
        approved_by=approved_by,
        after={"role": role.key, "scope_type": scope_type, "scope_id": scope_id, "expires_at": expires_at},
    )
    return assignment


@transaction.atomic
def revoke_assignment(*, actor: User, assignment: RoleAssignment) -> None:
    selectors.require(actor, "staff.manage")
    if assignment.user_id == actor.pk:
        raise Forbidden("You cannot change your own roles.", code="self_modification")
    _check_permissions(actor, set(assignment.role.permissions))
    if assignment.role.key == "super_admin":
        # Lock the role row so two concurrent revocations cannot remove the last two.
        Role.objects.select_for_update().get(pk=assignment.role_id)
        if selectors.role_holders("super_admin").exclude(pk=assignment.user_id).count() < 1:
            raise Conflict("At least one Super Admin must remain.", code="last_super_admin")
    record(
        actor=actor,
        action="role.revoked",
        target=assignment.user,
        label=assignment.user.display_name,
        before={
            "role": assignment.role.key,
            "scope_type": assignment.scope_type,
            "scope_id": assignment.scope_id,
        },
    )
    assignment.delete()
