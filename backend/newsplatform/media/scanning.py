"""Malware scanning. There is no "off": without a scanner, nothing is processed."""

import socket
import struct
from pathlib import Path
from typing import Protocol

from django.conf import settings

from newsplatform.common.errors import ServiceUnavailable
from newsplatform.integrations.base import guarded_call
from newsplatform.media.storage import Storage

EICAR = b"X5O!P%@AP[4\\PZX54(P^)7CC)7}$" + b"EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"


class NotReady(Exception):
    """The verdict is not there yet. Try again later."""


class Scanner(Protocol):
    remote: bool  # the verdict comes without us opening the file

    def is_clean(self, storage: Storage, key: str, path: Path | None) -> bool: ...


class GuardDuty:
    """GuardDuty Malware Protection for S3 tags every new object with its verdict. The bucket
    refuses to hand out an original without a clean one, so this comes before anything reads it."""

    remote = True

    def is_clean(self, storage: Storage, key: str, path: Path | None) -> bool:
        verdict = storage.tags(key).get("GuardDutyMalwareScanStatus")
        if verdict is None:
            raise NotReady
        # UNSUPPORTED, ACCESS_DENIED and FAILED are not proof of anything.
        return verdict == "NO_THREATS_FOUND"


class ClamAv:
    remote = False

    def __init__(self, host: str, port: int) -> None:
        self.address = (host, port)

    def is_clean(self, storage: Storage, key: str, path: Path | None) -> bool:
        if path is None:
            raise ValueError("clamd needs the file")
        with (
            guarded_call("clamav", "instream"),
            socket.create_connection(self.address, timeout=10) as conn,
            path.open("rb") as f,
        ):
            conn.settimeout(120)
            conn.sendall(b"zINSTREAM\0")
            while chunk := f.read(65536):
                conn.sendall(struct.pack(">I", len(chunk)) + chunk)
            conn.sendall(struct.pack(">I", 0))
            reply = b""
            while not reply.endswith(b"\0"):
                part = conn.recv(4096)
                if not part:
                    break
                reply += part
        if reply.rstrip(b"\0").endswith(b"OK"):
            return True
        if b"FOUND" in reply:
            return False
        raise RuntimeError("clamd did not give a verdict")  # never mistaken for clean


class EicarOnly:
    """Tests and local development: knows one signature. Refused by a system check when deployed."""

    remote = False

    def is_clean(self, storage: Storage, key: str, path: Path | None) -> bool:
        if path is None:
            raise ValueError("a file is needed")
        with path.open("rb") as f:
            tail = b""
            while chunk := f.read(1 << 20):
                if EICAR in tail + chunk:
                    return False
                tail = chunk[-len(EICAR) :]
        return True


def scanner() -> Scanner:
    local = settings.LOCAL_SCANNER
    if local == "eicar":
        return EicarOnly()
    if local.startswith("clamav://"):
        host, _, port = local.removeprefix("clamav://").partition(":")
        return ClamAv(host, int(port or 3310))
    if settings.IS_DEPLOYED:
        return GuardDuty()
    raise ServiceUnavailable("No malware scanner is configured.", code="scanner_not_configured")
