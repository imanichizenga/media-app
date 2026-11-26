# Postgres's search for when OpenSearch does not answer (ADR-0049). The column is nullable without a default (no table
# rewrite) and the indexes are built CONCURRENTLY (no lock on a table of millions). Vectors are filled by publishing
# and, for what was published before, by `manage.py search_reindex`.

import django.contrib.postgres.indexes
import django.contrib.postgres.search
import django.db.models.fields.json
from django.contrib.postgres.operations import AddIndexConcurrently, TrigramExtension
from django.db import migrations


class Migration(migrations.Migration):
    atomic = False

    dependencies = [
        ("content", "0005_short_labels"),
        ("taxonomy", "0002_short_labels"),
    ]

    operations = [
        TrigramExtension(),
        migrations.AddField(
            model_name="publication",
            name="search_vector",
            field=django.contrib.postgres.search.SearchVectorField(editable=False, null=True),
        ),
        AddIndexConcurrently(
            model_name="publication",
            index=django.contrib.postgres.indexes.GinIndex(
                fields=["search_vector"], name="publication_search"
            ),
        ),
        AddIndexConcurrently(
            model_name="publication",
            index=django.contrib.postgres.indexes.GinIndex(
                django.contrib.postgres.indexes.OpClass(
                    django.db.models.fields.json.KeyTextTransform("headline", "card"),
                    name="gin_trgm_ops",
                ),
                name="publication_headline_trgm",
            ),
        ),
    ]
