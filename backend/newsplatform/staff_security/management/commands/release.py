from typing import Any

from django.core.management import call_command
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = (
        "One-off release task, run as the schema owner before new code starts: migrate, then refresh grants."
    )

    def handle(self, *args: Any, **options: Any) -> None:
        call_command("check", deploy=True, fail_level="ERROR")
        call_command("migrate", interactive=False)
        call_command("provision_db_roles")
        call_command("verify_audit_chain")
