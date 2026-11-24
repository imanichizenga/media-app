from typing import Any

from newsplatform.integrations.base import Provider, ProviderConfig, Test, register_provider
from newsplatform.media import youtube
from newsplatform.media.sniff import sniff


class YouTubeConfig(ProviderConfig):
    pass


@register_provider
class YouTubeProvider(Provider[YouTubeConfig]):
    key, name, category = "youtube", "YouTube", "media"
    description_en = "Reads titles and thumbnails of pasted YouTube links. Needs no key."
    description_sw = "Husoma vichwa na picha za viungo vya YouTube. Haihitaji ufunguo."
    config_model = YouTubeConfig

    def test(self, config: YouTubeConfig, t: Test, params: dict[str, Any]) -> None:
        link = youtube.parse("https://www.youtube.com/watch?v=aqz-KE-bpKQ")  # Big Buck Bunny, CC BY 3.0
        t.step(
            "oembed", "Read a known video", "Soma video inayojulikana", lambda: youtube.metadata(link).title
        )
        t.step(
            "thumbnail",
            "Fetch its thumbnail",
            "Pata picha yake",
            lambda: sniff((youtube.thumbnail(link) or b"")[:64]) or "none",
            needs="oembed",
        )
