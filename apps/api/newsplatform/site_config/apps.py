from django.apps import AppConfig


class SiteConfigConfig(AppConfig):
    name = "newsplatform.site_config"

    def ready(self) -> None:
        from newsplatform.site_config import services  # noqa: F401  (registers approval actions)
