from typing import Any

from django.core.management.base import BaseCommand, CommandParser
from django.db import transaction

from newsplatform.audit.services import record
from newsplatform.site_config.models import SettingsSection
from newsplatform.staff_security.tasks import sync_waf_allowlist


class Command(BaseCommand):
    help = "Emergency: turn the admin IP allowlist off. Audited."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("--reason", required=True)

    def handle(self, *args: Any, **options: Any) -> None:
        with transaction.atomic():
            row = SettingsSection.objects.select_for_update().get(key="security")
            row.data = {**row.data, "ip_allowlist_enabled": False}
            row.version += 1
            row.save()
            record(
                actor=None,
                actor_label="break-glass",
                action="settings.break_glass",
                target=row,
                label="ip allowlist disabled",
                reason=options["reason"],
            )
        sync_waf_allowlist.delay()
        self.stdout.write("IP allowlist disabled")
