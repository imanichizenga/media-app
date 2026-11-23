import structlog
from celery import shared_task

from newsplatform.audit.services import verify_chain

log = structlog.get_logger(__name__)


@shared_task
def verify_chain_task() -> None:
    report = verify_chain()
    if report.ok:
        log.info("audit_chain_verified", checked=report.checked)
    else:
        # Alarmed on by name in CloudWatch: docs/runbooks/audit-chain-broken.md
        log.critical("audit_chain_broken", problems=report.problems)


@shared_task
def anchor_chain_task() -> None:
    from newsplatform.integrations.providers.audit_anchor import anchor_head

    anchor_head()
