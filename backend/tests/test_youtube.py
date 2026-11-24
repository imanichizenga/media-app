import json

import httpx
import pytest

from newsplatform.common.errors import DomainError, ServiceUnavailable
from newsplatform.common.http import SafeResponse
from newsplatform.media import youtube
from newsplatform.media.youtube import Link, parse

V = "aqz-KE-bpKQ"


@pytest.mark.parametrize(
    "url",
    [
        V,
        f"  https://www.youtube.com/watch?v={V}  ",
        f"http://youtube.com/watch?v={V}",
        f"youtube.com/watch?v={V}",
        f"//www.youtube.com/watch?v={V}",
        f"https://m.youtube.com/watch?v={V}&feature=share",
        f"https://music.youtube.com/watch?v={V}&list=RD",
        f"https://www.youtube.com/watch?app=desktop&v={V}&list=PL1&index=3",
        f"https://www.youtube.com/watch/{V}",
        f"https://youtu.be/{V}",
        f"https://youtu.be/{V}?si=abc",
        f"https://www.youtube.com/embed/{V}",
        f"https://www.youtube.com/embed/{V}?autoplay=1",
        f"https://www.youtube-nocookie.com/embed/{V}",
        f"https://www.youtube.com/v/{V}",
        f"https://www.youtube.com/e/{V}",
        f"https://www.youtube.com/live/{V}?feature=shared",
        f"https://WWW.YouTube.com/watch?v={V}",
        f"https://www.youtube.com/attribution_link?a=x&u=%2Fwatch%3Fv%3D{V}%26feature%3Dshare",
    ],
)
def test_every_form_gives_the_same_id(url):
    assert parse(url) == Link(V, 0, False)


def test_shorts_are_vertical():
    assert parse(f"https://youtube.com/shorts/{V}?feature=share") == Link(V, 0, True)


@pytest.mark.parametrize(
    ("suffix", "seconds"),
    [
        ("t=90", 90),
        ("t=90s", 90),
        ("t=1m30s", 90),
        ("t=1h2m3s", 3723),
        ("start=15", 15),
        ("t=x", 0),
        ("t=999999", 86400),
    ],
)
def test_start_times(suffix, seconds):
    assert parse(f"https://youtu.be/{V}?{suffix}").start == seconds
    assert parse(f"https://www.youtube.com/watch?v={V}#t=30").start == 30


@pytest.mark.parametrize(
    "url",
    [
        "",
        "short",
        "https://vimeo.com/1234",
        f"https://evil.example/watch?v={V}",
        f"https://youtube.com.evil.example/watch?v={V}",
        f"https://evil.example/?u=https://youtube.com/watch?v={V}",
        f"https://youtube.com@evil.example/watch?v={V}",
        f"javascript://youtube.com/watch?v={V}",
        f"file://youtube.com/watch?v={V}",
        "https://www.youtube.com/watch?v=tooshort",
        f"https://www.youtube.com/watch?v={V}extra",
        f"https://www.youtube.com/watch?v={V}%0a",
        "https://www.youtube.com/@channel",
        "https://www.youtube.com/playlist?list=PL1",
        "https://www.youtube.com/attribution_link?u=https://evil.example",
        "https://[::1",
        "https://youtu.be/" + "a" * 3000,
    ],
)
def test_everything_else_is_refused(url):
    with pytest.raises(DomainError) as e:
        parse(url)
    assert e.value.code == "not_youtube"


def answer(monkeypatch, status, body=b""):
    monkeypatch.setattr(youtube, "fetch", lambda *_, **__: SafeResponse(status, httpx.Headers(), body))


@pytest.mark.django_db
class TestMetadata:
    def test_keeps_text_only(self, monkeypatch):
        answer(
            monkeypatch,
            200,
            json.dumps(
                {"title": "T" * 400, "author_name": "A", "width": 200, "height": 113, "html": "<iframe>"}
            ).encode(),
        )
        found = youtube.metadata(parse(V))
        assert len(found.title) == 300
        assert "iframe" not in str(found)

    @pytest.mark.parametrize("status", [401, 403, 404])
    def test_private_or_deleted(self, monkeypatch, status):
        answer(monkeypatch, status)
        with pytest.raises(DomainError) as e:
            youtube.metadata(parse(V))
        assert e.value.code == "youtube_not_embeddable"

    @pytest.mark.parametrize(("status", "body"), [(500, b""), (200, b"<html>"), (200, b"{}"), (302, b"")])
    def test_outage(self, monkeypatch, status, body):
        answer(monkeypatch, status, body)
        with pytest.raises(ServiceUnavailable):
            youtube.metadata(parse(V))

    def test_thumbnail_falls_back(self, monkeypatch):
        asked = []

        def fake(method, url, **_):
            asked.append(url)
            return SafeResponse(200 if "hq" in url else 404, httpx.Headers(), b"img")

        monkeypatch.setattr(youtube, "fetch", fake)
        assert youtube.thumbnail(parse(V)) == b"img"
        assert len(asked) == 3
