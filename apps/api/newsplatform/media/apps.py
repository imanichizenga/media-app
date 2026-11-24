from django.apps import AppConfig


class MediaConfig(AppConfig):
    name = "newsplatform.media"

    def ready(self) -> None:
        from newsplatform.media import transcoding  # noqa: F401
        from newsplatform.realtime import topics

        topics.register("asset", "media.upload")
