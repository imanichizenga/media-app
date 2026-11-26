"""Compares each language's index with the database by id and etag, and repairs it (ADR-0049).

manage.py search_reconcile [--locale sw]
"""

from typing import Any

from django.core.management.base import BaseCommand

from newsplatform.search import indexing, mapping


class Command(BaseCommand):
    help = "Repair the search index where it differs from the database"

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument("--locale", choices=mapping.LOCALES)

    def handle(self, *args: Any, **options: Any) -> None:
        for locale in [options["locale"]] if options["locale"] else mapping.LOCALES:
            self.stdout.write(f"{locale}: {indexing.reconcile(locale)} repaired")
