from collections.abc import Callable
from dataclasses import dataclass
from datetime import timedelta
from typing import Any
from uuid import UUID

from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.approvals.models import ApprovalRequest, ApprovalStatus
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, Forbidden
from newsplatform.rbac import selectors as rbac

# execute(payload, requester, approver) runs inside the approval transaction.
Executor = Callable[[dict[str, Any], User, User], None]


@dataclass(frozen=True, slots=True)
class Action:
    key: str
    permission: str  # both the requester and the approver must hold it
    execute: Executor


_ACTIONS: dict[str, Action] = {}


def register(key: str, permission: str) -> Callable[[Executor], Executor]:
    def wrap(fn: Executor) -> Executor:
        _ACTIONS[key] = Action(key, permission, fn)
        return fn

    return wrap


def is_required(action: str) -> bool:
    from newsplatform.site_config.services import get_security

    mode = get_security().four_eyes
    if action not in _ACTIONS:
        raise KeyError(action)
    return mode == "on" or (mode == "auto" and settings.ENVIRONMENT == "prod")


@transaction.atomic
def request_approval(
    *, actor: User, action: str, summary: str, payload: dict[str, Any], dedupe_key: str, reason: str = ""
) -> ApprovalRequest:
    rbac.require(actor, _ACTIONS[action].permission)
    try:
        with transaction.atomic():
            req = ApprovalRequest.objects.create(
                action=action,
                summary=summary[:300],
                payload=payload,
                dedupe_key=dedupe_key,
                reason=reason,
                requested_by=actor,
                expires_at=timezone.now() + timedelta(hours=72),
            )
    except IntegrityError as exc:
        raise Conflict("This change is already waiting for approval.", code="approval_pending") from exc
    record(
        actor=actor,
        action="approval.requested",
        target=req,
        label=summary,
        reason=reason,
        after={"action": action, "payload": payload},
    )
    return req


def _lock(req_id: str | UUID) -> ApprovalRequest:
    req = (
        ApprovalRequest.objects.select_for_update(of=("self",)).select_related("requested_by").get(pk=req_id)
    )
    if req.status != ApprovalStatus.PENDING:
        raise Conflict("This request has already been decided.", code="approval_closed")
    return req


def _close(req: ApprovalRequest, status: ApprovalStatus, by: User | None, note: str) -> None:
    req.status, req.decided_by, req.decided_at, req.decision_note = status, by, timezone.now(), note
    req.save()


@transaction.atomic
def approve(*, actor: User, req_id: str | UUID, note: str = "") -> ApprovalRequest:
    req = _lock(req_id)
    if req.expires_at <= timezone.now():
        raise Conflict("This request has expired.", code="approval_expired")
    if req.requested_by_id == actor.pk:
        raise Forbidden("A different person must approve this.", code="four_eyes")
    action = _ACTIONS[req.action]
    rbac.require(actor, "approvals.decide")
    rbac.require(actor, action.permission)
    # The requester may have lost the permission, or the account, since asking.
    if not req.requested_by.can_sign_in or not rbac.has_perm(req.requested_by, action.permission):
        raise Conflict("The requester no longer has permission for this.", code="requester_unauthorised")
    action.execute(req.payload, req.requested_by, actor)
    _close(req, ApprovalStatus.EXECUTED, actor, note)
    record(
        actor=req.requested_by,
        approved_by=actor,
        action="approval.executed",
        target=req,
        label=req.summary,
        after={"action": req.action, "payload": req.payload},
        reason=note,
    )
    return req


@transaction.atomic
def reject(*, actor: User, req_id: str | UUID, note: str) -> ApprovalRequest:
    req = _lock(req_id)
    own = req.requested_by_id == actor.pk
    if not own:
        rbac.require(actor, "approvals.decide")
        rbac.require(actor, _ACTIONS[req.action].permission)
    _close(req, ApprovalStatus.CANCELLED if own else ApprovalStatus.REJECTED, actor, note)
    record(actor=actor, action=f"approval.{req.status}", target=req, label=req.summary, reason=note)
    return req
