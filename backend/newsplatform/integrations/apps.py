from django.apps import AppConfig


class IntegrationsConfig(AppConfig):
    name = "newsplatform.integrations"

    def ready(self) -> None:
        from newsplatform.integrations import services  # noqa: F401
        from newsplatform.integrations.providers import (  # noqa: F401
            apple_signin,
            audit_anchor,
            beem,
            google_signin,
            s3,
            ses,
            snippe,
            waf,
            web,
            youtube,
        )
        from newsplatform.realtime import topics

        topics.register("integration_test", "integrations.view")
