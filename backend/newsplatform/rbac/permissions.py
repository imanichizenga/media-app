from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from newsplatform.common.errors import StepUpRequired
from newsplatform.rbac.selectors import grants_for
from newsplatform.staff_security.authentication import session_of


class DenyAll(BasePermission):
    """Default everywhere: an endpoint with no explicit permission is unreachable."""

    def has_permission(self, request: Request, view: Any) -> bool:
        return False


class PublicEndpoint(BasePermission):
    """An explicit opt-in, so reviewers can grep for it."""

    def has_permission(self, request: Request, view: Any) -> bool:
        return True


class StaffPermission(BasePermission):
    """The view declares `perms = {"GET": "x.view", ...}`; a value of None means any active staff session.

    `step_up` lists the methods that need a recent MFA check.
    """

    def has_permission(self, request: Request, view: Any) -> bool:
        if request.auth is None:
            return False
        session = session_of(request)
        if not session.is_active_stage:
            return False
        perms: dict[str, str | None] = view.perms
        method = "GET" if request.method in ("HEAD", "OPTIONS") else str(request.method)
        if method not in perms:
            return False
        code = perms[method]
        # Scoped grants pass this gate; the service re-checks against the object itself.
        if code is not None and code not in grants_for(session.user).any:
            return False
        if method in getattr(view, "step_up", ()) and not session.has_recent_mfa():
            raise StepUpRequired("Confirm it's you to continue.")
        return True
