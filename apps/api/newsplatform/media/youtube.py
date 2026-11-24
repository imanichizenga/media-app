"""YouTube links, in every form people paste them."""

import json
import re
from dataclasses import dataclass
from urllib.parse import parse_qs, quote, urlparse

import httpx

from newsplatform.common.errors import DomainError, ServiceUnavailable
from newsplatform.common.http import fetch
from newsplatform.integrations.base import guarded_call

_ID = re.compile(r"[A-Za-z0-9_-]{11}")
_HOSTS = {
    "youtube.com",
    "www.youtube.com",
    "m.youtube.com",
    "music.youtube.com",
    "youtube-nocookie.com",
    "www.youtube-nocookie.com",
}
_PATHS = {"embed", "v", "e", "shorts", "live"}


@dataclass(frozen=True, slots=True)
class Link:
    video_id: str
    start: int
    vertical: bool


def _seconds(raw: str) -> int:
    if raw.isdigit():
        return min(int(raw), 86_400)
    match = re.fullmatch(r"(?:(\d{1,3})h)?(?:(\d{1,4})m)?(?:(\d{1,6})s)?", raw)
    if not match or not raw:
        return 0
    h, m, s = (int(g or 0) for g in match.groups())
    return min(h * 3600 + m * 60 + s, 86_400)


def parse(raw: str) -> Link:
    text = raw.strip()
    if _ID.fullmatch(text):
        return Link(text, 0, False)
    if "://" not in text:
        text = f"https://{text.removeprefix('//')}"
    try:
        url = urlparse(text)
        host = (url.hostname or "").lower()
    except ValueError:
        host = ""
    bad = DomainError("This is not a YouTube video address.", code="not_youtube")
    if not host or url.scheme not in ("http", "https") or len(text) > 2048:
        raise bad
    parts = [p for p in url.path.split("/") if p]
    query = parse_qs(url.query)
    ident, vertical = "", False
    if host in ("youtu.be", "www.youtu.be"):
        ident = parts[0] if parts else ""
    elif host in _HOSTS:
        if parts[:1] == ["watch"]:
            ident = query.get("v", [parts[1] if len(parts) > 1 else ""])[0]
        elif parts[:1] == ["attribution_link"]:
            inner = query.get("u", [""])[0]
            return parse(f"https://www.youtube.com{inner}") if inner.startswith("/watch") else _raise(bad)
        elif len(parts) > 1 and parts[0] in _PATHS:
            ident, vertical = parts[1], parts[0] == "shorts"
    if not _ID.fullmatch(ident):
        raise bad
    start = query.get("t", query.get("start", [""]))[0] or parse_qs(url.fragment).get("t", [""])[0]
    return Link(ident, _seconds(start), vertical)


def _raise(error: Exception) -> Link:
    raise error


@dataclass(frozen=True, slots=True)
class Metadata:
    title: str
    author: str
    width: int
    height: int


def metadata(link: Link) -> Metadata:
    """Official oEmbed, through the SSRF-safe client. Only text is kept: their HTML is never used."""
    page = quote(f"https://www.youtube.com/watch?v={link.video_id}", safe="")
    try:
        with guarded_call("youtube", "oembed"):
            res = fetch("GET", f"https://www.youtube.com/oembed?format=json&url={page}", max_bytes=100_000)
    except httpx.HTTPError as exc:
        raise ServiceUnavailable("YouTube cannot be reached.", code="youtube_unavailable") from exc
    if res.status in (400, 401, 403, 404):
        raise DomainError(
            "This video is private, deleted or cannot be embedded.", code="youtube_not_embeddable"
        )
    if res.status != 200:
        raise ServiceUnavailable("YouTube cannot be reached.", code="youtube_unavailable")
    try:
        data = json.loads(res.body)
        return Metadata(
            str(data["title"])[:300],
            str(data.get("author_name", ""))[:120],
            int(data["width"]),
            int(data["height"]),
        )
    except (ValueError, KeyError, TypeError) as exc:
        raise ServiceUnavailable("YouTube answered unexpectedly.", code="youtube_unavailable") from exc


def thumbnail(link: Link) -> bytes | None:
    """The largest there is. Mirrored through the normal image pipeline, never hotlinked."""
    for name in ("maxresdefault", "sddefault", "hqdefault"):
        with guarded_call("youtube", "thumbnail"):
            res = fetch("GET", f"https://i.ytimg.com/vi/{link.video_id}/{name}.jpg", max_bytes=5_000_000)
        if res.status == 200:
            return res.body
    return None
