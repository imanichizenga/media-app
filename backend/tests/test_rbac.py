import pytest
from django.utils import timezone

from newsplatform.accounts.models import UserStatus
from newsplatform.common.errors import Conflict, DomainError, Forbidden
from newsplatform.rbac import registry, selectors, services
from newsplatform.rbac.models import Role, RoleAssignment

pytestmark = pytest.mark.django_db
TREE = {"football": {"football", "sport"}, "sport": {"sport"}, "politics": {"politics"}}


class Post:
    def __init__(self, category):
        self.category = category

    def rbac_scopes(self):
        return [("category", self.category)]


@pytest.fixture
def scopes(monkeypatch):
    monkeypatch.setattr(registry, "_SCOPES", {"category": lambda i: TREE.get(i, set())})


def test_unknown_permission_is_an_error_not_a_denial(make_staff):
    with pytest.raises(KeyError):
        selectors.has_perm(make_staff(), "content.tyop")


def test_scoped_grant_covers_descendants_only(make_staff, roles, scopes):
    user = make_staff("contributor")
    RoleAssignment.objects.create(
        user=user, role=roles["section_editor"], scope_type="category", scope_id="sport"
    )
    assert selectors.has_perm(user, "content.publish", Post("sport"))
    assert selectors.has_perm(user, "content.publish", Post("football"))
    assert not selectors.has_perm(user, "content.publish", Post("politics"))
    assert not selectors.has_perm(user, "content.publish")


def test_scoped_grant_never_yields_unscopable_permission(make_staff, roles, scopes):
    user = make_staff("contributor")
    RoleAssignment.objects.create(user=user, role=roles["admin"], scope_type="category", scope_id="sport")
    assert not selectors.has_perm(user, "integrations.manage", Post("sport"))
    assert "staff.manage" not in selectors.grants_for(user).any


def test_expired_assignment_and_inactive_user_grant_nothing(make_staff):
    user = make_staff("admin")
    RoleAssignment.objects.filter(user=user).update(expires_at=timezone.now())
    assert not selectors.grants_for(user).any
    other = make_staff("admin")
    other.status = UserStatus.BANNED
    other.save()
    assert not selectors.grants_for(other).any


def test_cannot_grant_more_than_you_hold(make_staff, roles):
    admin, target = make_staff("admin"), make_staff("journalist")
    with pytest.raises(Forbidden) as e:
        services.assign_role(actor=admin, user=target, role=roles["super_admin"])
    assert e.value.code == "privilege_escalation"


def test_cannot_change_own_roles(make_staff, roles):
    boss = make_staff()
    with pytest.raises(Forbidden):
        services.assign_role(actor=boss, user=boss, role=roles["moderator"])
    with pytest.raises(Forbidden):
        services.revoke_assignment(actor=boss, assignment=boss.assignments.get())


def test_cannot_edit_a_role_you_hold_or_super_admin(make_staff, roles):
    admin, boss = make_staff("admin"), make_staff()
    body = {"name_en": "x", "name_sw": "x", "description": "", "permissions": []}
    with pytest.raises(Forbidden) as e:
        services.save_role(actor=admin, role=roles["admin"], **body)
    assert e.value.code in {"self_modification", "privilege_escalation"}
    with pytest.raises(Forbidden) as e:
        services.save_role(actor=boss, role=roles["super_admin"], **body)
    assert e.value.code == "system_role"


def test_cannot_strip_permissions_you_lack(make_staff, roles):
    admin = make_staff("admin")
    role = Role.objects.create(key="sec", name_en="s", name_sw="s", permissions=["settings.security"])
    with pytest.raises(Forbidden):
        services.save_role(actor=admin, role=role, name_en="s", name_sw="s", description="", permissions=[])


def test_system_roles_cannot_be_deleted_custom_in_use_neither(make_staff, roles):
    boss, target = make_staff(), make_staff("journalist")
    with pytest.raises(Forbidden):
        services.delete_role(actor=boss, role=roles["analyst"])
    role = services.save_role(
        actor=boss,
        role=None,
        key="desk",
        name_en="Desk",
        name_sw="Dawati",
        description="",
        permissions=["media.upload"],
    )
    services.assign_role(actor=boss, user=target, role=role)
    with pytest.raises(Conflict):
        services.delete_role(actor=boss, role=role)


def test_last_super_admin_is_protected(make_staff):
    a, b = make_staff(), make_staff()
    services.revoke_assignment(actor=a, assignment=b.assignments.get())
    c = make_staff()
    RoleAssignment.objects.filter(user=a).update(expires_at=timezone.now())
    d = make_staff()
    services.revoke_assignment(actor=c, assignment=d.assignments.get())
    with pytest.raises((Conflict, Forbidden)):
        services.revoke_assignment(actor=d, assignment=c.assignments.get())


def test_unknown_permission_or_scope_rejected(make_staff, roles):
    boss, target = make_staff(), make_staff("journalist")
    with pytest.raises(DomainError):
        services.save_role(
            actor=boss, role=None, key="x", name_en="x", name_sw="x", description="", permissions=["nope"]
        )
    with pytest.raises(DomainError):
        services.assign_role(
            actor=boss, user=target, role=roles["journalist"], scope_type="galaxy", scope_id="1"
        )


def test_system_role_edits_survive_resync(roles):
    Role.objects.filter(key="analyst").update(permissions=["analytics.view", "users.view"])
    Role.objects.filter(key="super_admin").update(permissions=[])
    services.sync_system_roles()
    assert Role.objects.get(key="analyst").permissions == ["analytics.view", "users.view"]
    assert set(Role.objects.get(key="super_admin").permissions) == set(registry.PERMISSIONS)
