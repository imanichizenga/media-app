"""Run as the schema owner. Gives the runtime role DML, but never UPDATE/DELETE on audit history."""

import os
from typing import Any

from django.core.management.base import BaseCommand
from django.db import connection
from psycopg import sql


class Command(BaseCommand):
    help = "Create or refresh the least-privilege runtime database role."

    def handle(self, *args: Any, **options: Any) -> None:
        role, password = os.environ["APP_DB_USER"], os.environ["APP_DB_PASSWORD"]
        ident = sql.Identifier(role)
        statements = [
            sql.SQL("ALTER ROLE {} LOGIN PASSWORD {} NOSUPERUSER NOCREATEDB NOCREATEROLE").format(
                ident, sql.Literal(password)
            ),
            sql.SQL("GRANT USAGE ON SCHEMA public TO {}").format(ident),
            sql.SQL("GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {}").format(
                ident
            ),
            sql.SQL("GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {}").format(ident),
            sql.SQL(
                "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE"
                " ON TABLES TO {}"
            ).format(ident),
            sql.SQL(
                "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO {}"
            ).format(ident),
            sql.SQL("REVOKE UPDATE, DELETE, TRUNCATE ON audit_auditentry, audit_chainanchor FROM {}").format(
                ident
            ),
            sql.SQL("REVOKE DELETE, TRUNCATE ON audit_chainhead FROM {}").format(ident),
            sql.SQL("REVOKE INSERT, UPDATE, DELETE ON django_migrations FROM {}").format(ident),
        ]
        with connection.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", [role])
            if not cur.fetchone():
                cur.execute(sql.SQL("CREATE ROLE {}").format(ident))
            for statement in statements:
                cur.execute(statement)
        self.stdout.write(f"Runtime role {role} provisioned")
