from celery import shared_task
from django.db import transaction
from django.utils import timezone

from newsplatform.approvals.models import ApprovalRequest, ApprovalStatus
from newsplatform.audit.services import record


@shared_task
def expire_requests() -> int:
    stale = ApprovalRequest.objects.filter(status=ApprovalStatus.PENDING, expires_at__lte=timezone.now())
    count = 0
    for pk in list(stale.values_list("pk", flat=True)):
        with transaction.atomic():
            req = ApprovalRequest.objects.select_for_update().get(pk=pk)
            if req.status == ApprovalStatus.PENDING:
                req.status = ApprovalStatus.EXPIRED
                req.save(update_fields=["status", "updated_at"])
                record(actor=None, action="approval.expired", target=req, label=req.summary)
                count += 1
    return count
