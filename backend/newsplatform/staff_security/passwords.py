import hashlib

import httpx
import structlog
from django.contrib.auth.hashers import make_password
from django.contrib.auth.password_validation import CommonPasswordValidator
from django.core.exceptions import ValidationError

from newsplatform.common.errors import DomainError
from newsplatform.common.http import fetch

log = structlog.get_logger(__name__)
MIN_LENGTH, MAX_LENGTH = 12, 256


def _breach_count(password: str) -> int | None:
    """HIBP k-anonymity: only five hash characters leave the server. None = service unavailable."""
    digest = hashlib.sha1(password.encode(), usedforsecurity=False).hexdigest().upper()
    try:
        res = fetch(
            "GET",
            f"https://api.pwnedpasswords.com/range/{digest[:5]}",
            headers={"Add-Padding": "true"},
            timeout=4,
        )
    except httpx.HTTPError:
        return None
    if res.status != 200:
        return None
    for line in res.body.decode().splitlines():
        suffix, _, count = line.partition(":")
        if suffix == digest[5:]:
            return int(count)
    return 0


def validate(password: str) -> None:
    """Length and breach exposure only: no composition rules."""
    if not MIN_LENGTH <= len(password) <= MAX_LENGTH:
        raise DomainError(f"Use at least {MIN_LENGTH} characters.", code="password_length")
    count = _breach_count(password)
    if count is None:
        log.warning("password_breach_check_unavailable")
        try:
            CommonPasswordValidator().validate(password)
            count = 0
        except ValidationError:
            count = 1
    if count:
        raise DomainError(
            "This password has appeared in a data breach. Choose another.", code="password_breached"
        )


# Verified against when the account does not exist, so timing does not reveal which emails do.
DUMMY_HASH = make_password("timing-equaliser")
