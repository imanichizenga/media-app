from celery import shared_task


@shared_task
def erase_due_readers() -> int:
    """Daily: readers whose grace period after asking to be deleted has passed (ADR-0050)."""
    from newsplatform.accounts.signin import erase_due

    return erase_due()
