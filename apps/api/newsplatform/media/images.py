"""Image derivatives. Nothing from the camera survives: no EXIF, GPS, XMP, IPTC or colour profile."""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import blurhash
import pyvips

from newsplatform.media.sniff import IMAGE_TYPES, sniff

WIDTHS = (320, 640, 960, 1280, 1920)
# Google asks for 1200px in these shapes; social cards use the first.
CROPS = {"16x9": (1200, 675), "4x3": (1200, 900), "1x1": (1200, 1200)}
MAX_PIXELS = 100_000_000
FORMATS: dict[str, tuple[str, str, dict[str, Any]]] = {
    "avif": ("avif", "image/avif", {"Q": 50, "effort": 4, "compression": "av1"}),
    "webp": ("webp", "image/webp", {"Q": 78, "effort": 4}),
    "jpeg": ("jpg", "image/jpeg", {"Q": 80, "optimize_coding": True, "interlace": True}),
}


class BadImage(Exception):
    """`code` is stored on the asset and translated in the admin."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(slots=True)
class Processed:
    width: int
    height: int
    blurhash: str
    color: str
    mime: str
    files: list[tuple[Path, str, str]] = field(default_factory=list)  # path, key suffix, content type
    variants: dict[str, dict[str, str]] = field(default_factory=dict)  # format → width → key suffix
    crops: dict[str, str] = field(default_factory=dict)


def _open(source: Path) -> tuple[Any, str]:
    with source.open("rb") as f:
        mime = sniff(f.read(64))
    if mime not in IMAGE_TYPES:
        raise BadImage("unsupported_type")
    try:
        header = pyvips.Image.new_from_file(str(source), access="sequential", fail_on="error")
        # Read from the header: a decompression bomb is refused before a single pixel is decoded.
        if header.width * header.height > MAX_PIXELS:
            raise BadImage("too_many_pixels")
        image = pyvips.Image.new_from_file(str(source), fail_on="error")
        image = image.autorot()
        if image.interpretation != "srgb":
            image = (
                image.icc_transform("srgb")
                if image.get_typeof("icc-profile-data")
                else image.colourspace("srgb")
            )
        elif image.get_typeof("icc-profile-data"):
            image = image.icc_transform("srgb")
        return image.cast("uchar").copy_memory(), mime
    except pyvips.Error as exc:
        raise BadImage("unreadable") from exc


def _flat(image: Any) -> Any:
    return image.flatten(background=[255, 255, 255]) if image.hasalpha() else image


def _crop(image: Any, width: int, height: int, focal: tuple[int, int]) -> Any:
    """The largest box of this shape that keeps the focal point as central as the edges allow."""
    scale = min(image.width / width, image.height / height)
    w, h = round(width * scale), round(height * scale)
    left = min(max(round(image.width * focal[0] / 1000 - w / 2), 0), image.width - w)
    top = min(max(round(image.height * focal[1] / 1000 - h / 2), 0), image.height - h)
    box = image.crop(left, top, w, h)
    # Never enlarged: a small photograph stays sharp and honest about its size.
    return box.thumbnail_image(width, height=height, size="down")


def process(source: Path, out: Path, focal: tuple[int, int] = (500, 500)) -> Processed:
    image, mime = _open(source)
    flat = _flat(image)
    result = Processed(image.width, image.height, _hash(flat), _dominant(flat), mime)
    wanted = [w for w in WIDTHS if w <= image.width] or [image.width]
    for width in wanted:
        sized = image if width == image.width else image.thumbnail_image(width, size="down")
        for name, (ext, content_type, options) in FORMATS.items():
            suffix = f"{width}.{ext}"
            path = out / suffix
            # Logos keep their transparency where the format has any.
            (_flat(sized) if name == "jpeg" else sized).write_to_file(str(path), keep="none", **options)
            result.files.append((path, suffix, content_type))
            result.variants.setdefault(name, {})[str(width)] = suffix
    for name, (width, height) in CROPS.items():
        suffix = f"crop-{name}.jpg"
        path = out / suffix
        _crop(flat, width, height, focal).write_to_file(str(path), keep="none", Q=82, optimize_coding=True)
        result.files.append((path, suffix, "image/jpeg"))
        result.crops[name] = suffix
    return result


def _hash(image: Any) -> str:
    small = image.thumbnail_image(64, height=64, size="down")[0:3] if image.bands >= 3 else image
    if small.bands < 3:
        small = small.colourspace("srgb")
    rows = [[list(small.getpoint(x, y))[:3] for x in range(small.width)] for y in range(small.height)]
    across = 4 if small.width >= small.height else 3
    return str(blurhash.encode(rows, components_x=across, components_y=7 - across))


def _dominant(image: Any) -> str:
    """The most common colour in a coarse histogram, so one bright object does not tint it."""
    small = image.thumbnail_image(96, height=96, size="down")
    if small.bands < 3:
        small = small.colourspace("srgb")
    small = small[0:3]
    data = bytes(small.write_to_memory())
    buckets: dict[tuple[int, int, int], list[int]] = {}
    for i in range(0, len(data), 3):
        r, g, b = data[i], data[i + 1], data[i + 2]
        cell = buckets.setdefault((r >> 5, g >> 5, b >> 5), [0, 0, 0, 0])
        cell[0] += 1
        cell[1] += r
        cell[2] += g
        cell[3] += b
    n, r, g, b = max(buckets.values())
    return f"#{r // n:02x}{g // n:02x}{b // n:02x}"
