import secrets
from datetime import timedelta
from typing import Any

from django.conf import settings
from django.contrib.auth.hashers import check_password
from django.db import transaction
from django.utils import timezone

from newsplatform.accounts.models import User, UserStatus
from newsplatform.approvals import services as approvals
from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.integrations.providers.ses import deliver
from newsplatform.rbac import selectors as rbac
from newsplatform.rbac import services as rbac_services
from newsplatform.rbac.models import Role, RoleAssignment
from newsplatform.staff_security import passwords, sessions
from newsplatform.staff_security.alerts import notify
from newsplatform.staff_security.models import StaffSession, StaffToken, TokenKind, TotpDevice

INVITE_TTL, RESET_TTL = timedelta(hours=72), timedelta(hours=4)
Grant = dict[str, str]


def link(kind: str, token: str) -> str:
    # In the fragment, so the token never reaches server logs or Referer headers.
    return f"{settings.ADMIN_ORIGIN}/{kind}#{token}"


def _issue(
    *, kind: TokenKind, email: str, actor: User | None, ttl: timedelta, **extra: Any
) -> tuple[StaffToken, str]:
    raw = secrets.token_urlsafe(32)
    token = StaffToken.objects.create(
        kind=kind,
        email=email,
        token_hash=sessions.hash_token(raw),
        created_by=actor,
        expires_at=timezone.now() + ttl,
        **extra,
    )
    return token, raw


def _roles(grants: list[Grant]) -> list[tuple[Role, Grant]]:
    found = {r.key: r for r in Role.objects.filter(key__in=[g["role"] for g in grants])}
    if missing := [g["role"] for g in grants if g["role"] not in found]:
        raise DomainError("Unknown role", code="unknown_role", roles=missing)
    return [(found[g["role"]], g) for g in grants]


def _send(email: str, url: str, subject: str) -> bool:
    return deliver(to=email, subject=subject, text=f"{subject}\n\n{url}\n")


def _create_invite(
    actor: User | None, email: str, grants: list[Grant], approved_by: User | None = None
) -> tuple[StaffToken, str]:
    if User.objects.filter(email__iexact=email, is_staff_member=True).exists():
        raise Conflict("This person is already on the staff.", code="already_staff")
    StaffToken.objects.filter(
        kind=TokenKind.INVITE, email__iexact=email, used_at__isnull=True, revoked_at__isnull=True
    ).update(revoked_at=timezone.now())
    token, raw = _issue(kind=TokenKind.INVITE, email=email, actor=actor, ttl=INVITE_TTL, grants=grants)
    record(
        actor=actor,
        approved_by=approved_by,
        action="staff.invited",
        target=token,
        label=email,
        after={"grants": grants},
        actor_label="bootstrap" if actor is None else "",
    )
    return token, link("invite", raw)


@transaction.atomic
def invite(*, actor: User, email: str, grants: list[Grant]) -> dict[str, Any]:
    rbac.require(actor, "staff.invite")
    email, pairs = email.strip().lower(), _roles(grants)
    if not pairs:
        raise DomainError("Choose at least one role", code="validation_error")
    for role, grant in pairs:
        rbac_services.check_can_grant(
            actor=actor, target=None, role=role, scope_type=grant.get("scope_type", "")
        )
    if any(r.is_privileged for r, _ in pairs) and approvals.is_required("staff.invite_privileged"):
        req = approvals.request_approval(
            actor=actor,
            action="staff.invite_privileged",
            dedupe_key=email,
            summary=f"Invite {email} with a privileged role",
            payload={"email": email, "grants": grants},
        )
        return {"approval": req, "invite": None, "emailed": False, "link": None}
    token, url = _create_invite(actor, email, grants)
    emailed = _send(email, url, "You are invited to the newsroom / Umealikwa kwenye chumba cha habari")
    # Shown once to the inviter only when no email could be sent.
    return {"approval": None, "invite": token, "emailed": emailed, "link": None if emailed else url}


@approvals.register("staff.invite_privileged", "staff.invite")
def _execute_invite(payload: dict[str, Any], requester: User, approver: User) -> None:
    pairs = _roles(payload["grants"])
    for role, grant in pairs:
        for person in (requester, approver):  # neither can lend authority they lack
            rbac_services.check_can_grant(
                actor=person, target=None, role=role, scope_type=grant.get("scope_type", "")
            )
    _, url = _create_invite(requester, payload["email"], payload["grants"], approver)
    if not _send(
        payload["email"], url, "You are invited to the newsroom / Umealikwa kwenye chumba cha habari"
    ):
        raise Conflict(
            "Configure email first: an approved invitation is delivered only by email.", code="email_required"
        )


def _usable(raw: str, kind: TokenKind) -> StaffToken:
    token = (
        StaffToken.objects.select_for_update().filter(token_hash=sessions.hash_token(raw), kind=kind).first()
    )
    if token is None or not token.is_usable:
        raise NotFound("This link is invalid or has expired.", code="invalid_link")
    return token


@transaction.atomic
def accept_invite(*, raw: str, display_name: str, password: str, locale: str) -> User:
    token = _usable(raw, TokenKind.INVITE)
    passwords.validate(password)
    user = User.objects.filter(email__iexact=token.email).first()
    if user and user.is_staff_member:
        raise Conflict("This person is already on the staff.", code="already_staff")
    if user:
        if not user.can_sign_in:
            raise Conflict("This account is suspended.", code="account_suspended")
        user.display_name, user.locale = display_name, locale
        user.set_password(password)
        user.save()
    else:
        user = User.objects.create_user(
            email=token.email, password=password, display_name=display_name, locale=locale
        )
    for role, grant in _roles(token.grants):
        # If the inviter has lost their authority since, the grant must not go through.
        if token.created_by:
            rbac_services.check_can_grant(
                actor=token.created_by, target=None, role=role, scope_type=grant.get("scope_type", "")
            )
        rbac_services.assign_role(
            actor=None,
            user=user,
            role=role,
            scope_type=grant.get("scope_type", ""),
            scope_id=grant.get("scope_id", ""),
        )
    user.refresh_from_db()
    token.used_at, token.user = timezone.now(), user
    token.save()
    record(actor=user, action="staff.invite_accepted", target=user, label=user.display_name)
    return user


@transaction.atomic
def issue_reset(*, actor: User, user: User, reset_mfa: bool) -> dict[str, Any]:
    rbac.require(actor, "staff.manage")
    if actor.pk == user.pk:
        raise DomainError("Use your own security page.", code="self_modification", status=403)
    # You may only reset people whose authority you already hold; otherwise a reset is an account takeover.
    if not rbac.grants_for(user).everywhere <= rbac.grants_for(actor).everywhere:
        raise DomainError(
            "This person holds permissions you do not.", code="privilege_escalation", status=403
        )
    if reset_mfa and approvals.is_required("staff.reset_mfa"):
        req = approvals.request_approval(
            actor=actor,
            action="staff.reset_mfa",
            dedupe_key=str(user.pk),
            summary=f"Reset MFA for {user.display_name}",
            payload={"user": str(user.pk)},
        )
        return {"approval": req, "emailed": False, "link": None}
    return _reset(actor, user, reset_mfa, None)


def _reset(actor: User, user: User, reset_mfa: bool, approver: User | None) -> dict[str, Any]:
    _, raw = _issue(
        kind=TokenKind.RESET,
        email=user.email or "",
        actor=actor,
        ttl=RESET_TTL,
        user=user,
        reset_mfa=reset_mfa,
    )
    sessions.revoke_all(user, "credential_reset")
    record(
        actor=actor,
        approved_by=approver,
        action="staff.reset_issued",
        target=user,
        label=user.display_name,
        after={"reset_mfa": reset_mfa},
    )
    url = link("reset", raw)
    emailed = _send(user.email or "", url, "Reset your sign-in / Weka upya taarifa za kuingia")
    return {"approval": None, "emailed": emailed, "link": None if emailed or approver else url}


@approvals.register("staff.reset_mfa", "staff.manage")
def _execute_reset(payload: dict[str, Any], requester: User, approver: User) -> None:
    user = User.objects.get(pk=payload["user"])
    if approver.pk == user.pk:
        raise DomainError("You cannot approve a reset of your own account.", code="four_eyes", status=403)
    for person in (requester, approver):
        if not rbac.grants_for(user).everywhere <= rbac.grants_for(person).everywhere:
            raise DomainError(
                "This person holds permissions you do not.", code="privilege_escalation", status=403
            )
    if not _reset(requester, user, True, approver)["emailed"]:
        raise Conflict(
            "Configure email first: an approved reset is delivered only by email.", code="email_required"
        )


@transaction.atomic
def complete_reset(*, raw: str, password: str) -> User:
    token = _usable(raw, TokenKind.RESET)
    user = token.user
    if user is None or not user.can_sign_in:
        raise NotFound("This link is invalid or has expired.", code="invalid_link")
    passwords.validate(password)
    user.set_password(password)
    user.save()
    if token.reset_mfa:
        user.passkeys.all().delete()
        user.recovery_codes.all().delete()
        TotpDevice.objects.filter(user=user).delete()
    token.used_at = timezone.now()
    token.save()
    sessions.revoke_all(user, "credential_reset")
    record(
        actor=user,
        action="staff.reset_completed",
        target=user,
        label=user.display_name,
        after={"reset_mfa": token.reset_mfa},
    )
    transaction.on_commit(lambda: notify(user, "credentials_changed", "password reset"))
    return user


@transaction.atomic
def change_password(*, session: StaffSession, current: str, new: str) -> None:
    user = session.user
    if not check_password(current, user.password):
        raise DomainError("Your current password is incorrect.", code="invalid_credentials")
    passwords.validate(new)
    user.set_password(new)
    user.save()
    sessions.revoke_all(user, "password_changed", keep=session)
    record(actor=user, action="staff.password_changed", target=user, label=user.display_name)
    transaction.on_commit(lambda: notify(user, "credentials_changed", "password"))


@transaction.atomic
def set_status(*, actor: User, user: User, active: bool, reason: str) -> None:
    rbac.require(actor, "staff.manage")
    if actor.pk == user.pk:
        raise DomainError("You cannot change your own status.", code="self_modification", status=403)
    if not rbac.grants_for(user).everywhere <= rbac.grants_for(actor).everywhere:
        raise DomainError(
            "This person holds permissions you do not.", code="privilege_escalation", status=403
        )
    if not active and RoleAssignment.objects.filter(user=user, role__key="super_admin").exists():
        Role.objects.select_for_update().get(key="super_admin")
        if rbac.role_holders("super_admin").exclude(pk=user.pk).count() < 1:
            raise Conflict("At least one Super Admin must remain.", code="last_super_admin")
    before = user.status
    user.status = UserStatus.ACTIVE if active else UserStatus.DEACTIVATED
    user.save(update_fields=["status", "updated_at"])
    if not active:
        sessions.revoke_all(user, "deactivated")
    record(
        actor=actor,
        action="staff.status_changed",
        target=user,
        label=user.display_name,
        reason=reason,
        before={"status": before},
        after={"status": user.status},
    )


@transaction.atomic
def grant_role(
    *, actor: User, user: User, role: Role, scope_type: str, scope_id: str
) -> RoleAssignment | ApprovalRequest:
    rbac_services.check_can_grant(actor=actor, target=user, role=role, scope_type=scope_type)
    if role.is_privileged and approvals.is_required("role.grant_privileged"):
        return approvals.request_approval(
            actor=actor,
            action="role.grant_privileged",
            dedupe_key=f"{user.pk}:{role.key}",
            summary=f"Grant {role.name_en} to {user.display_name}",
            payload={"user": str(user.pk), "role": role.key},
        )
    return rbac_services.assign_role(
        actor=actor, user=user, role=role, scope_type=scope_type, scope_id=scope_id
    )


@approvals.register("role.grant_privileged", "staff.manage")
def _execute_grant(payload: dict[str, Any], requester: User, approver: User) -> None:
    user, role = User.objects.get(pk=payload["user"]), Role.objects.get(key=payload["role"])
    if approver.pk == user.pk:
        raise DomainError("You cannot approve a role for yourself.", code="four_eyes", status=403)
    rbac_services.check_can_grant(actor=approver, target=user, role=role)
    rbac_services.assign_role(actor=requester, user=user, role=role, approved_by=approver)
