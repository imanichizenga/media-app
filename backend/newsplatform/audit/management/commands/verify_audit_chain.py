from typing import Any

from django.core.management.base import BaseCommand, CommandError

from newsplatform.audit.services import verify_chain


class Command(BaseCommand):
    help = "Verify the audit hash chain and its anchors."

    def handle(self, *args: Any, **options: Any) -> None:
        report = verify_chain()
        if not report.ok:
            raise CommandError(f"AUDIT CHAIN BROKEN: {report.problems}")
        self.stdout.write(f"OK: {report.checked} entries, {report.anchors_checked} anchors")
