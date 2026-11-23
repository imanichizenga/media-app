from celery import shared_task

from newsplatform.integrations import services


@shared_task
def run_test(run_id: str) -> None:
    services.execute_test(run_id)
