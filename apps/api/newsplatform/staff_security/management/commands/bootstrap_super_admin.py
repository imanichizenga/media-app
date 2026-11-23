from typing import Any

from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.core.validators import validate_email
from django.db import transaction

from newsplatform.rbac.selectors import role_holders
from newsplatform.staff_security.staff import _create_invite


class Command(BaseCommand):
    help = "Issue a single-use Super Admin invitation. Works only until two Super Admins exist."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("email")

    @transaction.atomic
    def handle(self, *args: Any, **options: Any) -> None:
        validate_email(options["email"])
        if role_holders("super_admin").count() >= 2:
            raise CommandError("Two Super Admins already exist. Invite from the console instead.")
        _, url = _create_invite(None, options["email"].lower(), [{"role": "super_admin"}])
        self.stdout.write(url)
