"""Logos come from outside, and an SVG is a program. Nothing is trusted: the file is rebuilt from an
allowlist, element by element, and what cannot be kept without changing the drawing is refused
with a reason."""

import hashlib
import re
from dataclasses import dataclass
from typing import Any
from xml.etree import ElementTree as ET  # builds and writes; defusedxml reads

import pyvips
from defusedxml import ElementTree as SafeET
from defusedxml.common import DefusedXmlException
from django.db import IntegrityError, transaction

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import DomainError
from newsplatform.site_config.models import BrandLogo, BrandLogoFile

MAX_BYTES = 1_000_000
MAX_ELEMENTS, MAX_DEPTH = 4000, 24
SVG, XLINK = "http://www.w3.org/2000/svg", "http://www.w3.org/1999/xlink"
ELEMENTS = {
    "svg", "g", "path", "rect", "circle", "ellipse", "line", "polyline", "polygon", "defs", "clipPath",
    "mask", "linearGradient", "radialGradient", "stop", "use", "symbol", "image", "title", "desc",
}  # fmt: skip
ATTRIBUTES = {
    "id", "d", "x", "y", "x1", "y1", "x2", "y2", "cx", "cy", "r", "rx", "ry", "fx", "fy", "width", "height",
    "points", "viewBox", "preserveAspectRatio", "transform", "fill", "fill-rule", "fill-opacity", "clip-rule",
    "clip-path", "clipPathUnits", "mask", "maskUnits", "maskContentUnits", "stroke", "stroke-width",
    "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "stroke-dasharray", "stroke-dashoffset",
    "stroke-opacity", "opacity", "color", "offset", "stop-color", "stop-opacity", "gradientUnits",
    "gradientTransform", "spreadMethod", "href", "display", "visibility", "vector-effect",
}  # fmt: skip
# Dropping these would change the drawing, so the file is sent back instead.
REFUSED = {"style": "logo_style", "text": "logo_text", "tspan": "logo_text", "filter": "logo_filter"}
_LOCAL_URL = re.compile(r"url\(\s*(['\"]?)#[A-Za-z_][\w.:-]*\1\s*\)")
_IMAGE = re.compile(r"data:image/(png|jpeg|webp);base64,[A-Za-z0-9+/=\s]+")
_LOCAL_REF = re.compile(r"#[A-Za-z_][\w.:-]*")
_BAD = re.compile(
    r"(javascript|vbscript|data|file|https?|ftp)\s*:|expression\s*\(|@import|\\|<|//", re.IGNORECASE
)

HEIGHTS = {"1x": 32, "2x": 64, "3x": 96, "share": 160}
SIZES = {"1x": 64, "2x": 128, "3x": 192, "large": 512}
TYPES = {"svg": "image/svg+xml", "png": "image/png"}


def _no(code: str, text: str) -> DomainError:
    return DomainError(text, code=code)


def _safe(name: str, value: str) -> bool:
    if name == "href":
        return bool(_LOCAL_REF.fullmatch(value) or _IMAGE.fullmatch(value))
    if "url(" in value.lower():
        return bool(_LOCAL_URL.fullmatch(value.strip()))
    return not _BAD.search(value)


def _attributes(node: ET.Element, local: str) -> dict[str, str]:
    found = dict(node.attrib)
    for rule in found.pop("style", "").split(";"):  # inline properties become attributes, or go
        name, _, value = rule.partition(":")
        if value.strip():
            found.setdefault(name.strip(), value.strip())
    out: dict[str, str] = {}
    for raw, value in found.items():
        name = "href" if raw == f"{{{XLINK}}}href" else raw
        if name not in ATTRIBUTES or not _safe(name, value):
            continue
        if name == "href" and (local == "image") != bool(_IMAGE.fullmatch(value)):
            continue  # pictures only in <image>, references only elsewhere
        out[name] = value
    return out


def clean_svg(data: bytes) -> bytes:
    try:
        root = SafeET.fromstring(data, forbid_dtd=False, forbid_entities=True, forbid_external=True)
    except DefusedXmlException as exc:
        raise _no("logo_unsafe", "The file declares entities or refers outside itself.") from exc
    except (ET.ParseError, ValueError, LookupError) as exc:
        raise _no("logo_unreadable", "This is not a readable SVG.") from exc
    if root.tag != f"{{{SVG}}}svg":
        raise _no("logo_unreadable", "This is not a readable SVG.")
    count = 0

    def rebuild(node: ET.Element, depth: int) -> ET.Element | None:
        nonlocal count
        count += 1
        if count > MAX_ELEMENTS or depth > MAX_DEPTH:
            raise _no("logo_too_complex", "The drawing is too complex for a logo.")
        if not isinstance(node.tag, str) or not node.tag.startswith(f"{{{SVG}}}"):
            return None
        local = node.tag.removeprefix(f"{{{SVG}}}")
        if local in REFUSED:
            raise _no(REFUSED[local], "Export the logo with outlines and plain attributes.")
        if local not in ELEMENTS:
            return None
        made = ET.Element(node.tag, _attributes(node, local))
        if local in ("title", "desc"):
            made.text = (node.text or "")[:200]
        for child in node:
            kept = rebuild(child, depth + 1)
            if kept is not None:
                made.append(kept)
        return made

    out = rebuild(root, 0)
    assert out is not None  # noqa: S101 (the root is an svg element)
    if not out.get("viewBox"):
        size = [re.fullmatch(r"(\d+(\.\d+)?)(px)?", out.get(n, "")) for n in ("width", "height")]
        if not all(size):
            raise _no("logo_no_viewbox", "The SVG needs a viewBox.")
        out.set("viewBox", f"0 0 {size[0][1]} {size[1][1]}")  # type: ignore[index]
    for name in ("width", "height"):
        out.attrib.pop(name, None)
    ET.register_namespace("", SVG)
    text: bytes = ET.tostring(out, encoding="utf-8")
    return text


@dataclass(frozen=True, slots=True)
class Made:
    source: str
    width: int
    height: int
    files: dict[str, bytes]


def _rgba(image: Any) -> Any:
    if image.interpretation != "srgb":
        image = image.colourspace("srgb")
    return image if image.hasalpha() else image.addalpha()


def _png(image: Any) -> bytes:
    out: bytes = image.cast("uchar").pngsave_buffer(compression=9, keep="none")
    return out


def _white(image: Any) -> Any:
    alpha = image[3]
    return alpha.new_from_image([255, 255, 255]).bandjoin(alpha).copy(interpretation="srgb")


def make(kind: str, data: bytes) -> Made:
    if len(data) > MAX_BYTES:
        raise _no("logo_too_large", "A logo may be at most 1 MB.")
    png = data.startswith(b"\x89PNG\r\n\x1a\n")
    try:
        if png:
            source, clean = "png", b""
            header = pyvips.Image.new_from_buffer(data, "", access="sequential")
            if header.width * header.height > 25_000_000:
                raise _no("logo_too_complex", "The picture is too large for a logo.")
            full = _rgba(pyvips.Image.new_from_buffer(data, "", fail_on="error"))
        else:
            source, clean = "svg", clean_svg(data)
            drawn = pyvips.Image.new_from_buffer(clean, "", access="sequential")
            if not drawn.width or not drawn.height or max(drawn.width, drawn.height) > 20_000:
                raise _no("logo_unreadable", "The drawing has no usable size.")
            full = _rgba(pyvips.Image.new_from_buffer(clean, "", scale=1600 / max(drawn.width, drawn.height)))
        full = full.copy_memory()
    except pyvips.Error as exc:
        raise _no("logo_unreadable", "The file could not be read.") from exc
    if full[3].max() == 0:
        raise _no("logo_empty", "The logo is empty.")
    box = full[3].find_trim(threshold=1, background=0)  # the margins are the layout's business
    shape = full.width / full.height
    if kind == "wordmark":
        full = full.crop(*box)
        shape = full.width / full.height
        if not 1.5 <= shape <= 12:
            raise _no("logo_shape", "A wordmark is wide: between 1.5 and 12 times its height.")
        if source == "png" and full.height < HEIGHTS["share"]:
            raise _no("logo_small", f"A PNG wordmark is at least {HEIGHTS['share']} pixels high.")
        if full[3].avg() > 250:
            raise _no("logo_opaque", "A wordmark needs a transparent background.")
    else:
        if abs(shape - 1) > 0.02:
            raise _no("logo_shape", "The symbol is square.")
        if source == "png" and full.width < SIZES["large"]:
            raise _no("logo_small", f"A PNG symbol is at least {SIZES['large']} pixels wide.")
    files: dict[str, bytes] = {"logo.svg": clean} if clean and kind == "symbol" else {}
    if clean and kind == "wordmark":
        files["logo.svg"] = _cropped(
            clean, box, drawn.width, drawn.height, 1600 / max(drawn.width, drawn.height)
        )
    for name, height in (HEIGHTS if kind == "wordmark" else SIZES).items():
        small = full.resize(height / full.height)
        files[f"{name}.png"] = _png(small)
        if kind == "wordmark":
            files[f"white-{name}.png"] = _png(_white(small))
    return Made(source, full.width, full.height, files)


def _cropped(svg: bytes, box: tuple[int, int, int, int], width: int, height: int, scale: float) -> bytes:
    """The same trim for the drawing: a tighter viewBox."""
    root = SafeET.fromstring(svg)
    x0, y0, w, h = (float(v) for v in re.split(r"[\s,]+", root.get("viewBox", "").strip()))
    kx, ky = w / (width * scale), h / (height * scale)
    left, top, bw, bh = box
    parts = (x0 + left * kx, y0 + top * ky, bw * kx, bh * ky)
    root.set("viewBox", " ".join(f"{p:.3f}".rstrip("0").rstrip(".") for p in parts))
    out: bytes = ET.tostring(root, encoding="utf-8")
    return out


@transaction.atomic
def upload(*, actor: User, kind: str, data: bytes) -> BrandLogo:
    made = make(kind, data)
    digest = hashlib.sha256(b"".join(made.files[n] for n in sorted(made.files))).hexdigest()[:32]
    try:
        with transaction.atomic():
            logo = BrandLogo.objects.create(
                kind=kind,
                source=made.source,
                digest=digest,
                width=made.width,
                height=made.height,
                uploaded_by=actor,
            )
    except IntegrityError:  # the same file again
        return BrandLogo.objects.get(kind=kind, digest=digest)
    BrandLogoFile.objects.bulk_create(BrandLogoFile(logo=logo, name=n, data=d) for n, d in made.files.items())
    record(actor=actor, action="brand.logo_uploaded", target=logo, label=kind, after={"digest": digest})
    return logo


def body(logo: BrandLogo | None, *, white: bool = False) -> dict[str, Any] | None:
    """Root-relative addresses that never change their content."""
    if logo is None:
        return None
    base, pre = f"/theme/logo/{logo.kind}-{logo.digest}/", "white-" if white else ""
    names = HEIGHTS if logo.kind == "wordmark" else SIZES
    return {
        "id": str(logo.pk),
        "width": logo.width,
        "height": logo.height,
        "derived": white,
        "svg": f"{base}logo.svg" if logo.source == "svg" and not white else "",
        "png": {n: f"{base}{pre}{n}.png" for n in names},
    }
