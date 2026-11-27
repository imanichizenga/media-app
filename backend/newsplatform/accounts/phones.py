"""Phone numbers as readers type them, to E.164. Tanzania first: a local 07…/06… number becomes +255…."""

import re

_DIGITS = re.compile(r"[\s().-]")


def normalise(raw: str, default_country: str = "255") -> str | None:
    text = _DIGITS.sub("", raw or "")
    if text.startswith("00"):
        text = "+" + text[2:]
    if text.startswith("0") and len(text) == 10:  # a local number: 0712 345 678
        text = f"+{default_country}{text[1:]}"
    elif not text.startswith("+") and text.startswith(default_country) and len(text) >= 11:
        text = "+" + text
    if not re.fullmatch(r"\+[1-9][0-9]{6,14}", text):
        return None
    if text.startswith("+255") and not re.fullmatch(r"\+255[67][0-9]{8}", text):
        return None  # Tanzanian mobiles are 6x/7x and nine digits
    return text


def country_of(phone: str, allowed: list[str]) -> str | None:
    """The allowed calling code this number belongs to, longest first, or None."""
    for code in sorted(allowed, key=len, reverse=True):
        if phone.startswith("+" + code):
            return code
    return None


def masked(phone: str) -> str:
    return phone[:4] + " ••• ••• " + phone[-3:] if len(phone) > 8 else "•••"
