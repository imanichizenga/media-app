"""Permission catalogue and system roles. Code owns which permissions exist; the DB owns who has them."""

from collections.abc import Callable
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Perm:
    code: str
    en: str
    sw: str
    scopable: bool = False
    sensitive: bool = False


_P = [
    Perm("content.create", "Create content", "Kuunda maudhui", True),
    Perm("content.edit_own", "Edit own content", "Kuhariri maudhui yako", True),
    Perm("content.edit_others", "Edit others' content", "Kuhariri maudhui ya wengine", True),
    Perm("content.review", "Review submissions", "Kukagua maudhui", True),
    Perm("content.publish", "Publish content", "Kuchapisha maudhui", True),
    Perm("content.publish_direct", "Publish without review", "Kuchapisha bila ukaguzi", True),
    Perm("content.delete", "Delete content", "Kufuta maudhui", True, True),
    Perm("taxonomy.manage", "Manage categories and tags", "Kusimamia makundi na lebo", True),
    Perm("media.upload", "Upload media", "Kupakia media"),
    Perm("media.manage", "Manage media library", "Kusimamia maktaba ya media"),
    Perm("live.go_live", "Go live", "Kurusha mubashara"),
    Perm("live.moderate_chat", "Moderate live chat", "Kusimamia gumzo mubashara"),
    Perm("live.manage", "Manage live streams", "Kusimamia mirusho"),
    Perm("moderation.review", "Review reports", "Kukagua ripoti", True),
    Perm("moderation.ban_user", "Ban users", "Kufungia watumiaji", False, True),
    Perm("moderation.manage_rules", "Manage moderation rules", "Kusimamia kanuni"),
    Perm("engagement.manage_policy", "Manage engagement policies", "Kusimamia sera za ushiriki"),
    Perm("notifications.send", "Send notifications", "Kutuma arifa"),
    Perm("recommendations.manage", "Manage recommendations", "Kusimamia mapendekezo"),
    Perm("ads.manage", "Manage ads", "Kusimamia matangazo", False, True),
    Perm("analytics.view", "View analytics", "Kuona takwimu"),
    Perm("analytics.view_users", "View per-user analytics", "Kuona takwimu za mtumiaji", False, True),
    Perm("users.view", "View users", "Kuona watumiaji"),
    Perm("users.manage", "Manage users", "Kusimamia watumiaji", False, True),
    Perm("staff.view", "View staff", "Kuona wafanyakazi"),
    Perm("staff.invite", "Invite staff", "Kualika wafanyakazi", False, True),
    Perm("staff.manage", "Manage staff accounts", "Kusimamia akaunti za wafanyakazi", False, True),
    Perm("roles.manage", "Manage roles", "Kusimamia majukumu", False, True),
    Perm("integrations.view", "View integrations", "Kuona miunganisho"),
    Perm("integrations.manage", "Manage integrations", "Kusimamia miunganisho", False, True),
    Perm(
        "integrations.override_test",
        "Activate despite a failed test",
        "Kuwasha licha ya jaribio kufeli",
        False,
        True,
    ),
    Perm("approvals.decide", "Decide approval requests", "Kuamua maombi ya idhini", False, True),
    Perm("settings.view", "View settings", "Kuona mipangilio"),
    Perm("settings.manage", "Manage site settings", "Kusimamia mipangilio"),
    Perm("settings.security", "Manage security settings", "Kusimamia usalama", False, True),
    Perm("audit.view", "View audit and auth logs", "Kuona kumbukumbu"),
    Perm("audit.export", "Export logs", "Kuhamisha kumbukumbu", False, True),
    Perm("logs.view", "View system logs", "Kuona kumbukumbu za mfumo"),
]
PERMISSIONS: dict[str, Perm] = {p.code: p for p in _P}
_ALL = frozenset(PERMISSIONS)
_WRITE = {"content.create", "content.edit_own", "media.upload"}
_EDIT = _WRITE | {"content.edit_others", "content.review", "content.publish"}


@dataclass(frozen=True, slots=True)
class SystemRole:
    key: str
    en: str
    sw: str
    permissions: frozenset[str]
    staff: bool = True
    privileged: bool = False


SYSTEM_ROLES: list[SystemRole] = [
    SystemRole("super_admin", "Super Admin", "Msimamizi Mkuu", _ALL, privileged=True),
    SystemRole(
        "admin",
        "Admin",
        "Msimamizi",
        _ALL - {"integrations.override_test", "settings.security"},
        privileged=True,
    ),
    SystemRole(
        "editor_in_chief",
        "Editor-in-Chief",
        "Mhariri Mkuu",
        frozenset(
            _EDIT
            | {
                "content.publish_direct",
                "content.delete",
                "taxonomy.manage",
                "media.manage",
                "live.go_live",
                "live.moderate_chat",
                "live.manage",
                "engagement.manage_policy",
                "notifications.send",
                "recommendations.manage",
                "moderation.review",
                "analytics.view",
                "staff.view",
            }
        ),
    ),
    SystemRole(
        "section_editor",
        "Section Editor",
        "Mhariri wa Kitengo",
        frozenset(_EDIT | {"media.manage", "live.go_live", "live.moderate_chat", "analytics.view"}),
    ),
    SystemRole(
        "journalist", "Journalist", "Mwandishi", frozenset(_WRITE | {"live.go_live", "live.moderate_chat"})
    ),
    SystemRole("contributor", "Contributor", "Mchangiaji", frozenset(_WRITE)),
    SystemRole(
        "moderator",
        "Moderator",
        "Msimamizi wa Maoni",
        frozenset({"moderation.review", "moderation.ban_user", "live.moderate_chat", "users.view"}),
    ),
    SystemRole("analyst", "Analyst", "Mchambuzi", frozenset({"analytics.view"})),
    SystemRole("verified_user", "Verified User", "Mtumiaji Aliyethibitishwa", frozenset(), staff=False),
    SystemRole("user", "User", "Mtumiaji", frozenset(), staff=False),
]

# Given a scope id, return every scope id that contains it, itself included. Later apps register theirs.
ScopeAncestors = Callable[[str], set[str]]
_SCOPES: dict[str, ScopeAncestors] = {}


def register_scope(scope_type: str, ancestors: ScopeAncestors) -> None:
    _SCOPES[scope_type] = ancestors


def scope_ancestors(scope_type: str, scope_id: str) -> set[str]:
    resolver = _SCOPES.get(scope_type)
    return resolver(scope_id) if resolver else set()


def scope_exists(scope_type: str, scope_id: str) -> bool:
    """A resolver answers with the empty set for an id it does not know."""
    return bool(scope_ancestors(scope_type, scope_id))


def scope_types() -> set[str]:
    return set(_SCOPES)
