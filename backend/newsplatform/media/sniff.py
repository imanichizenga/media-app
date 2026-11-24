"""What a file is, from its bytes. Names and declared types are hints from a stranger."""

_IMAGES = [
    (b"\xff\xd8\xff", 0, "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", 0, "image/png"),
    (b"GIF87a", 0, "image/gif"),
    (b"GIF89a", 0, "image/gif"),
    (b"WEBP", 8, "image/webp"),
]
_HEIF = {
    b"avif": "image/avif",
    b"avis": "image/avif",
}
_MP4 = {
    b"isom",
    b"iso2",
    b"iso4",
    b"iso5",
    b"iso6",
    b"mp41",
    b"mp42",
    b"avc1",
    b"M4V ",
    b"MSNV",
    b"3gp4",
    b"3gp5",
    b"3g2a",
    b"dash",
}

IMAGE_TYPES = frozenset({"image/jpeg", "image/png", "image/webp", "image/avif"})
VIDEO_TYPES = frozenset({"video/mp4", "video/quicktime", "video/webm"})


def sniff(head: bytes) -> str:
    """Empty when it is nothing we accept. SVG and GIF are not photographs; HEIC has no free decoder."""
    for magic, offset, mime in _IMAGES:
        if head[offset : offset + len(magic)] == magic and (offset == 0 or head[:4] == b"RIFF"):
            return mime
    if head[4:8] == b"ftyp":
        brand = head[8:12]
        if brand in _HEIF:
            return _HEIF[brand]
        if brand == b"qt  ":
            return "video/quicktime"
        if brand in _MP4:
            return "video/mp4"
    if head[:4] == b"\x1a\x45\xdf\xa3" and b"webm" in head[:64]:
        return "video/webm"
    return ""
