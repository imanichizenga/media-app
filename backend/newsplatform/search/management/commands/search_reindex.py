"""Builds each language's index anew and swaps it in (ADR-0049); without OpenSearch, the Postgres vectors.

manage.py search_reindex [--locale sw] [--vectors-only]
"""

from typing import Any

from django.core.management.base import BaseCommand

from newsplatform.content.models import Publication
from newsplatform.search import client, indexing, mapping, vectors


class Command(BaseCommand):
    help = "Rebuild the search index of each language with no downtime, and the Postgres search vectors"

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument("--locale", choices=mapping.LOCALES)
        parser.add_argument("--vectors-only", action="store_true")

    def handle(self, *args: Any, **options: Any) -> None:
        locales = [options["locale"]] if options["locale"] else list(mapping.LOCALES)
        for locale in locales:
            if options["vectors_only"] or not client.configured():
                count = 0
                for batch in indexing._batches(locale):
                    vectors.write(batch)
                    count += len(batch)
                self.stdout.write(f"{locale}: {count} search vectors written (Postgres)")
                continue
            result = indexing.reindex(locale)
            self.stdout.write(
                f"{locale}: {result['documents']} documents in {result['index']}, "
                f"{result['repaired']} repaired, previous {result['previous'] or 'none'}"
            )
        left = Publication.objects.filter(search_vector__isnull=True).count()
        if left:
            self.stderr.write(f"{left} publications still without a search vector")
