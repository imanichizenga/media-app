"""Paid reading (ADR-0052).

A story marked for subscribers is published like any other, and its card is everyone's. What everyone is
served (and the CDN keeps) is its opening, `preview_paragraphs` of text; the whole story is asked for by the
reader, signed in, and given only while they have paid time left. Payments go through Snippe: a USSD push to
the reader's phone, or Snippe's hosted checkout for cards. Snippe's webhook is what completes a payment;
asking Snippe is the fallback, while the reader watches, for a webhook that is late.
"""

import calendar
import secrets
from datetime import datetime, timedelta
from typing import Any
from uuid import UUID

import structlog
from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.common.errors import DomainError, NotFound, ServiceUnavailable
from newsplatform.integrations.base import StepFailed
from newsplatform.integrations.providers import snippe as provider
from newsplatform.integrations.providers.snippe import SnippeConfig
from newsplatform.subscriptions.models import (
    Interval,
    Method,
    Payment,
    PaymentStatus,
    Plan,
    Subscription,
    WebhookEvent,
)

log = structlog.get_logger(__name__)

# Blocks of words: what a preview may hold. Pictures, video and embeds are the subscriber's.
_TEXT = {"paragraph", "heading", "quote", "list"}
_ASK_EVERY = timedelta(seconds=5)
_FINAL = {"completed", "failed", "voided", "expired"}


# ---- settings ----
def rules() -> Any:
    from newsplatform.site_config.services import get_section

    return get_section("subscriptions")[0]


def snippe() -> SnippeConfig | None:
    from newsplatform.integrations.services import get_active

    return get_active("snippe", SnippeConfig)


def local() -> bool:
    """Pretend payments: local and test only (settings refuse it in deployed environments)."""
    return bool(settings.LOCAL_PAYMENTS)


def methods() -> list[str]:
    r = rules()
    config = snippe()
    found = []
    if r.mobile_money and (config is not None or local()):
        found.append(Method.MOBILE.value)
    if r.cards and ((config is not None and config.cards) or local()):
        found.append(Method.CARD.value)
    return found


# ---- the lock ----
def preview(body: dict[str, Any], paragraphs: int) -> dict[str, Any]:
    kept: list[dict[str, Any]] = []
    words = 0
    for block in body.get("blocks", []):
        if block.get("type") not in _TEXT:
            continue  # a picture or a video between paragraphs is the subscriber's
        kept.append(block)
        if block.get("type") != "heading":
            words += 1
        if words >= paragraphs:
            break
    return {**body, "blocks": kept}


def locked(article: dict[str, Any]) -> dict[str, Any]:
    """What everyone is given of a story: all of it, or its opening when it is for subscribers."""
    if not article.get("premium"):
        return {**article, "locked": False}
    r = rules()
    if not r.enabled:
        return {**article, "locked": False}
    body = preview(article["body"], r.preview_paragraphs)
    from newsplatform.content import blocks

    used = {str(i) for i in blocks.asset_ids(body)}
    return {
        **article,
        "body": body,
        "assets": {k: v for k, v in article.get("assets", {}).items() if k in used},
        "locked": True,
    }


def active(reader: User | None) -> Subscription | None:
    if reader is None:
        return None
    return (
        Subscription.objects.select_related("plan")
        .filter(reader=reader, ends_at__gt=timezone.now())
        .order_by("-ends_at")
        .first()
    )


def full(reader: User, post_id: UUID, locale: str) -> dict[str, Any]:
    """The whole story, for a reader with paid time left."""
    from newsplatform.content import selectors
    from newsplatform.content.models import Publication

    row = Publication.objects.filter(post_id=post_id, locale=locale).first()
    if row is None:
        raise NotFound("Not found")
    article = selectors.current(row.article)
    if article["premium"] and rules().enabled and active(reader) is None:
        raise DomainError("This story is for subscribers.", code="subscription_required", status=402)
    return {**article, "locked": False, "modified_at": row.modified_at.isoformat()}


# ---- plans ----
def plans() -> list[Plan]:
    return list(Plan.objects.filter(is_active=True).order_by("interval", "position", "price"))


def plan_body(p: Plan, locale: str) -> dict[str, Any]:
    en = locale == "en"
    return {
        "id": str(p.pk),
        "code": p.code,
        "interval": p.interval,
        "price": p.price,
        "currency": p.currency,
        "name": p.name_en if en else p.name_sw,
        "tagline": p.tagline_en if en else p.tagline_sw,
        "features": list(p.features_en if en else p.features_sw),
        "badge": p.badge_en if en else p.badge_sw,
        "tone": p.tone,
        "highlighted": p.highlighted,
        # A year against twelve of the month's: what the yearly card may say it saves.
        "monthly_equivalent": round(p.price / 12) if p.interval == Interval.YEAR else p.price,
    }


def offer(locale: str) -> dict[str, Any]:
    r = rules()
    return {
        "enabled": r.enabled,
        "preview_paragraphs": r.preview_paragraphs,
        "methods": methods(),
        "plans": [plan_body(p, locale) for p in plans()],
    }


def add_period(start: datetime, interval: str) -> datetime:
    months = 12 if interval == Interval.YEAR else 1
    month = start.month - 1 + months
    year, month = start.year + month // 12, month % 12 + 1
    day = min(start.day, calendar.monthrange(year, month)[1])
    return start.replace(year=year, month=month, day=day)


# ---- paying ----
def _customer(reader: User) -> dict[str, str]:
    name = (reader.display_name or reader.username or "Reader").strip()
    first, _, last = name.partition(" ")
    return {
        "firstname": first[:40] or "Reader",
        "lastname": (last or first)[:40],
        "email": reader.contact_email or reader.email or "",
    }


def start(*, reader: User, plan_id: str, method: str, phone: str = "", return_url: str = "") -> Payment:
    plan = Plan.objects.filter(pk=plan_id, is_active=True).first() if _uuid(plan_id) else None
    if plan is None:
        raise DomainError("Choose a plan.", code="validation_error", field="plan")
    if method not in methods():
        raise DomainError("This way of paying is not available.", code="method_unavailable", field="method")
    if plan.price < provider.MINIMUM:
        raise DomainError(
            "This plan's price is below what can be paid.", code="validation_error", field="plan"
        )
    to = ""
    if method == Method.MOBILE:
        from newsplatform.accounts.phones import normalise

        to = normalise(phone or reader.phone or "") or ""
        if not to.startswith("+255"):
            raise DomainError("Use a Tanzanian mobile number.", code="invalid_phone", field="phone")
    if (
        Payment.objects.filter(
            reader=reader, status=PaymentStatus.PENDING, created_at__gt=timezone.now() - timedelta(minutes=10)
        ).count()
        >= 5
    ):
        raise DomainError("Too many payments waiting. Finish one first.", code="rate_limited", status=429)
    payment = Payment.objects.create(
        reader=reader, plan=plan, method=method, amount=plan.price, currency=plan.currency, phone=to
    )
    meta = {"payment": str(payment.pk), "plan": plan.code}
    config = snippe()
    try:
        if config is None:
            if not local():
                raise ServiceUnavailable("Payments are not set up.", code="payments_unavailable")
            payment.reference = f"local-{secrets.token_hex(8)}"
            if method == Method.CARD:
                payment.checkout_url = _local_return(return_url, payment)
        elif method == Method.MOBILE:
            made = provider.push(
                config,
                key=payment.pk.hex[:30],
                amount=plan.price,
                phone=to,
                customer=_customer(reader),
                metadata=meta,
            )
            payment.reference = str(made.get("reference", ""))
        else:
            made = provider.checkout(
                config,
                amount=plan.price,
                description=plan.name_en,
                customer={
                    "name": reader.display_name,
                    "phone": reader.phone or "",
                    "email": _customer(reader)["email"],
                },
                redirect_url=return_url or "",
                metadata=meta,
            )
            payment.reference = str(made.get("reference", ""))
            payment.checkout_url = str(made.get("checkout_url") or made.get("payment_link_url") or "")
    except StepFailed as exc:
        payment.status, payment.failure = PaymentStatus.FAILED, exc.detail[:200]
        payment.save(update_fields=["status", "failure", "updated_at"])
        log.warning("payment.refused", payment=str(payment.pk), detail=exc.detail)
        raise DomainError("The payment could not be started. Try again.", code="payment_failed") from exc
    payment.save(update_fields=["reference", "checkout_url", "updated_at"])
    return payment


def _uuid(value: str) -> bool:
    try:
        UUID(str(value))
    except ValueError:
        return False
    return True


def _local_return(return_url: str, payment: Payment) -> str:
    joiner = "&" if "?" in return_url else "?"
    return f"{return_url}{joiner}payment={payment.pk}" if return_url else ""


def get(reader: User, payment_id: UUID) -> Payment:
    payment = Payment.objects.select_related("plan").filter(pk=payment_id, reader=reader).first()
    if payment is None:
        raise NotFound("Not found")
    return payment


def check(payment: Payment) -> Payment:
    """While the reader waits: ask Snippe, at most every few seconds, in case its webhook is late."""
    if payment.status != PaymentStatus.PENDING:
        return payment
    now = timezone.now()
    if payment.checked_at and now - payment.checked_at < _ASK_EVERY:
        return payment
    Payment.objects.filter(pk=payment.pk).update(checked_at=now)
    payment.checked_at = now
    if payment.reference.startswith("local-"):
        # Approved on the phone a moment later, as a reader would.
        if now - payment.created_at > timedelta(seconds=4):
            return settle(payment.reference, "completed", channel="local")
        return payment
    config = snippe()
    if config is None or not payment.reference or payment.method == Method.CARD:
        return payment
    try:
        found = provider.status(config, payment.reference)
    except StepFailed, ServiceUnavailable:
        return payment
    state = str(found.get("status", ""))
    if state in _FINAL:
        channel = found.get("channel")
        return settle(
            payment.reference,
            state,
            channel=str(channel.get("provider", "")) if isinstance(channel, dict) else "",
        )
    return payment


@transaction.atomic
def settle(reference: str, state: str, *, channel: str = "", payment_id: str = "") -> Payment:
    """Snippe's last word on a payment. Paid: the reader's time is added after whatever they have left."""
    rows = Payment.objects.select_for_update().select_related("plan")
    payment = rows.filter(reference=reference).first() if reference else None
    if payment is None and payment_id and _uuid(payment_id):
        payment = rows.filter(pk=payment_id).first()
    if payment is None:
        raise NotFound("No such payment")
    if payment.status != PaymentStatus.PENDING:
        return payment
    now = timezone.now()
    if state == "completed":
        payment.status, payment.completed_at, payment.channel = PaymentStatus.COMPLETED, now, channel[:40]
        payment.save(update_fields=["status", "completed_at", "channel", "updated_at"])
        last = (
            Subscription.objects.select_for_update()
            .filter(reader_id=payment.reader_id, ends_at__gt=now)
            .order_by("-ends_at")
            .first()
        )
        begins = last.ends_at if last else now
        Subscription.objects.create(
            reader_id=payment.reader_id,
            plan=payment.plan,
            starts_at=begins,
            ends_at=add_period(begins, payment.plan.interval),
            payment=payment,
        )
        log.info("subscription.paid", payment=str(payment.pk), plan=payment.plan.code)
    else:
        payment.status = {
            "failed": PaymentStatus.FAILED,
            "voided": PaymentStatus.VOIDED,
            "expired": PaymentStatus.EXPIRED,
        }.get(state, PaymentStatus.FAILED)
        payment.save(update_fields=["status", "updated_at"])
    return payment


def webhook(raw: bytes, headers: dict[str, str]) -> bool:
    """Snippe telling of a payment. False when it is not Snippe's (or too old) to believe."""
    import json

    config = snippe()
    if config is None:
        return False
    if not provider.verify(
        config,
        raw=raw,
        timestamp=headers.get("X-Webhook-Timestamp", ""),
        signature=headers.get("X-Webhook-Signature", ""),
    ):
        return False
    try:
        event = json.loads(raw)
    except ValueError:
        return False
    kind = str(event.get("type") or event.get("event") or "")
    data = event.get("data") if isinstance(event.get("data"), dict) else event
    event_id = str(event.get("id") or f"{kind}:{data.get('reference', '')}")[:80]
    if not kind.startswith("payment."):
        return True
    try:
        with transaction.atomic():
            WebhookEvent.objects.create(id=event_id, kind=kind[:40])
    except IntegrityError:
        return True  # told before
    state = kind.removeprefix("payment.")
    channel = data.get("channel")
    metadata = data.get("metadata") if isinstance(data.get("metadata"), dict) else {}
    try:
        settle(
            str(data.get("reference", "")),
            state,
            channel=str(channel.get("provider", "")) if isinstance(channel, dict) else "",
            payment_id=str(metadata.get("payment", "")),
        )
    except NotFound:
        log.warning("payment.webhook_unknown", reference=str(data.get("reference", "")))
    return True


def payment_body(p: Payment) -> dict[str, Any]:
    return {
        "id": str(p.pk),
        "status": p.status,
        "method": p.method,
        "amount": p.amount,
        "currency": p.currency,
        "plan": p.plan.code,
        "checkout_url": p.checkout_url,
        "completed_at": p.completed_at.isoformat() if p.completed_at else None,
    }


def mine(reader: User, locale: str) -> dict[str, Any]:
    s = active(reader)
    return {
        "active": s is not None,
        "plan": plan_body(s.plan, locale) if s else None,
        "ends_at": s.ends_at.isoformat() if s else None,
    }
