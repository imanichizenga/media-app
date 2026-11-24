"""What clients need to show a file. Keys are relative; the CDN address comes from site-config."""

from typing import Any

from newsplatform.media.models import Asset


def _common(asset: Asset, locale: str) -> dict[str, Any]:
    return {
        "id": str(asset.pk),
        "alt": asset.alt_en if locale == "en" else asset.alt_sw,
        "credit": asset.credit,
        "width": asset.width,
        "height": asset.height,
        "blurhash": asset.blurhash,
        "color": asset.dominant_color,
    }


def _folder(keys: dict[str, str]) -> str:
    return next(iter(keys.values())).rpartition("/")[0] + "/" if keys else ""


def image(asset: Asset, locale: str) -> dict[str, Any]:
    """File names are `<base><width>.<avif|webp|jpg>` and `<crops>crop-<16x9|4x3|1x1>.jpg`. Spelling out every
    key would make a card ten times larger, on networks where that is a second of waiting."""
    sizes = asset.outputs.get("variants", {}).get("jpeg", {})
    return {
        "kind": "image",
        **_common(asset, locale),
        "focal": [asset.focal_x, asset.focal_y],
        "base": _folder(sizes),
        "widths": sorted(int(w) for w in sizes),
        "crops": _folder(asset.outputs.get("crops", {})),
    }


def video(asset: Asset, locale: str) -> dict[str, Any]:
    out = asset.outputs
    return {
        "kind": "video",
        **_common(asset, locale),
        "duration_ms": asset.duration_ms,
        "hls": out.get("hls", ""),
        "poster": out.get("poster", ""),
        "sprite": out.get("sprite", ""),
        "sprite_vtt": out.get("sprite_vtt", ""),
    }
