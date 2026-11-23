from django.apps import AppConfig
from django.db.models.signals import post_migrate


class RbacConfig(AppConfig):
    name = "newsplatform.rbac"

    def ready(self) -> None:
        from newsplatform.rbac.services import sync_system_roles

        post_migrate.connect(lambda **_: sync_system_roles(), sender=self, weak=False)
