from dataclasses import dataclass
from typing import Any, Protocol

from django.db.models import Q, QuerySet
from django.utils import timezone

from newsplatform.accounts.models import User, UserStatus
from newsplatform.common.errors import Forbidden
from newsplatform.rbac.models import Role, RoleAssignment
from newsplatform.rbac.registry import PERMISSIONS, scope_ancestors


class Scoped(Protocol):
    """Objects that live inside scopes, e.g. a post inside a category."""

    def rbac_scopes(self) -> list[tuple[str, str]]: ...


@dataclass(frozen=True, slots=True)
class Grants:
    everywhere: frozenset[str]
    scoped: dict[tuple[str, str], frozenset[str]]

    @property
    def any(self) -> frozenset[str]:
        return self.everywhere.union(*self.scoped.values())

    def allows(self, code: str, obj: Scoped | None = None) -> bool:
        if code not in PERMISSIONS:
            raise KeyError(f"Unknown permission {code}")
        if code in self.everywhere:
            return True
        if obj is None or not PERMISSIONS[code].scopable:
            return False
        return any(
            code in self.scoped.get((kind, ancestor), frozenset())
            for kind, ident in obj.rbac_scopes()
            for ancestor in scope_ancestors(kind, ident)
        )


def active_assignments() -> QuerySet[RoleAssignment]:
    return RoleAssignment.objects.filter(
        Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now()), user__status=UserStatus.ACTIVE
    )


def grants_for(user: User) -> Grants:
    """Read from the database on every request: revocation must be immediate."""
    everywhere: set[str] = set()
    scoped: dict[tuple[str, str], set[str]] = {}
    rows = active_assignments().filter(user=user).values_list("role__permissions", "scope_type", "scope_id")
    for perms, kind, ident in rows:
        known = set(perms) & PERMISSIONS.keys()
        if kind:
            scoped.setdefault((kind, ident), set()).update(p for p in known if PERMISSIONS[p].scopable)
        else:
            everywhere |= known
    return Grants(frozenset(everywhere), {k: frozenset(v) for k, v in scoped.items()})


def has_perm(user: User, code: str, obj: Scoped | None = None) -> bool:
    return grants_for(user).allows(code, obj)


def require(user: User, code: str, obj: Scoped | None = None) -> None:
    if not has_perm(user, code, obj):
        raise Forbidden("You do not have permission to do this.", permission=code)


def holders_of(code: str) -> QuerySet[User]:
    ids = active_assignments().filter(role__permissions__contains=[code], scope_type="").values("user_id")
    return User.objects.filter(id__in=ids, is_staff_member=True)


def role_holders(key: str) -> QuerySet[User]:
    return User.objects.filter(id__in=active_assignments().filter(role__key=key).values("user_id"))


def roles() -> QuerySet[Role]:
    return Role.objects.order_by("-is_system", "key")


def snapshot(role: Role) -> dict[str, Any]:
    return {
        "key": role.key,
        "name_en": role.name_en,
        "name_sw": role.name_sw,
        "permissions": sorted(role.permissions),
    }
