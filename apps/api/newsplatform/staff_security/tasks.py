from datetime import timedelta

import structlog
from celery import shared_task
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.staff_security.models import AuthEvent, StaffSession, StaffToken

log = structlog.get_logger(__name__)


@shared_task(autoretry_for=(Exception,), retry_backoff=10, retry_kwargs={"max_retries": 4})
def send_alert(user_id: str, subject: str, text: str) -> None:
    from newsplatform.integrations.providers.ses import deliver

    user = User.objects.filter(pk=user_id).first()
    if user and user.email and not deliver(to=user.email, subject=subject, text=text):
        log.warning("security_alert_not_emailed", reason="email integration is not active")


@shared_task
def sync_waf_allowlist() -> None:
    from newsplatform.integrations.providers.waf import push_allowlist
    from newsplatform.site_config.services import get_security

    policy = get_security()
    push_allowlist(policy.ip_allowlist_enabled, policy.ip_allowlist)


@shared_task
def prune() -> None:
    now = timezone.now()
    StaffSession.objects.filter(expires_at__lt=now - timedelta(days=90)).delete()
    StaffToken.objects.filter(expires_at__lt=now - timedelta(days=90)).delete()
    AuthEvent.objects.filter(created_at__lt=now - timedelta(days=400)).delete()
