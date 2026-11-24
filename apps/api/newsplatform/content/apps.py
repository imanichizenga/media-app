from django.apps import AppConfig


class ContentConfig(AppConfig):
    name = "newsplatform.content"

    def ready(self) -> None:
        from newsplatform.content import services  # noqa: F401
        from newsplatform.realtime import topics

        topics.register("post", "content.create")
