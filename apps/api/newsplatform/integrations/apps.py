from django.apps import AppConfig


class IntegrationsConfig(AppConfig):
    name = "newsplatform.integrations"

    def ready(self) -> None:
        from newsplatform.integrations import services  # noqa: F401
        from newsplatform.integrations.providers import audit_anchor, s3, ses, waf, web  # noqa: F401
        from newsplatform.realtime import topics

        topics.register("integration_test", "integrations.view")
