"""Web Push without a library: the message encrypted for one browser (RFC 8291, aes128gcm) and the site's
signature that push services ask for (VAPID, RFC 8292)."""

from __future__ import annotations

import base64
import json
import os
import time
from dataclasses import dataclass
from urllib.parse import urlsplit

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

# The push services of Chrome, Edge, Firefox and Safari. A browser hands the server an address to post
# to; only these are ever posted to, so a subscription cannot point the server at anything else.
PUSH_HOSTS = (
    "fcm.googleapis.com",
    "android.googleapis.com",
    "updates.push.services.mozilla.com",
    "push.services.mozilla.com",
    ".push.apple.com",
    ".notify.windows.com",
)
RECORD_SIZE = 4096


def b64u(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def unb64u(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def allowed(endpoint: str) -> bool:
    parts = urlsplit(endpoint)
    host = (parts.hostname or "").lower()
    if parts.scheme != "https" or parts.port not in (None, 443) or parts.username or parts.password:
        return False
    return any(host == h.lstrip(".") or (h.startswith(".") and host.endswith(h)) for h in PUSH_HOSTS)


def new_key() -> tuple[str, bytes]:
    """(public key as browsers want it, private key as PKCS#8 DER)."""
    key = ec.generate_private_key(ec.SECP256R1())
    public = key.public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint
    )
    private = key.private_bytes(
        serialization.Encoding.DER, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
    )
    return b64u(public), private


def _hkdf(salt: bytes, ikm: bytes, info: bytes, length: int) -> bytes:
    return HKDF(algorithm=hashes.SHA256(), length=length, salt=salt, info=info).derive(ikm)


def encrypt(payload: bytes, p256dh: str, auth: str, *, salt: bytes | None = None) -> bytes:
    """One record, aes128gcm: the header (salt, record size, the server's one-time key), then the text."""
    browser = unb64u(p256dh)
    secret = unb64u(auth)
    if len(browser) != 65 or len(secret) != 16:
        raise ValueError("Not a browser's push keys")
    browser_key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), browser)
    mine = ec.generate_private_key(ec.SECP256R1())
    mine_public = mine.public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint
    )
    shared = mine.exchange(ec.ECDH(), browser_key)
    salt = salt or os.urandom(16)
    ikm = _hkdf(secret, shared, b"WebPush: info\x00" + browser + mine_public, 32)
    cek = _hkdf(salt, ikm, b"Content-Encoding: aes128gcm\x00", 16)
    nonce = _hkdf(salt, ikm, b"Content-Encoding: nonce\x00", 12)
    if len(payload) > RECORD_SIZE - 17 - 86:
        raise ValueError("A push message is at most about 4 KB")
    body = AESGCM(cek).encrypt(nonce, payload + b"\x02", None)  # \x02: the last (and only) record
    return salt + RECORD_SIZE.to_bytes(4, "big") + bytes([len(mine_public)]) + mine_public + body


def vapid(endpoint: str, private_der: bytes, public: str, subject: str, *, hours: int = 12) -> str:
    """The Authorization header: a JWT (ES256) for the push service's origin, signed with the site's key."""
    parts = urlsplit(endpoint)
    claims = {
        "aud": f"{parts.scheme}://{parts.netloc}",
        "exp": int(time.time()) + hours * 3600,
        "sub": subject,
    }
    head = b64u(json.dumps({"typ": "JWT", "alg": "ES256"}, separators=(",", ":")).encode())
    body = b64u(json.dumps(claims, separators=(",", ":")).encode())
    key = serialization.load_der_private_key(private_der, password=None)
    assert isinstance(key, ec.EllipticCurvePrivateKey)  # noqa: S101 (made by new_key)
    r, s = decode_dss_signature(key.sign(f"{head}.{body}".encode(), ec.ECDSA(hashes.SHA256())))
    signature = b64u(r.to_bytes(32, "big") + s.to_bytes(32, "big"))
    return f"vapid t={head}.{body}.{signature}, k={public}"


@dataclass(frozen=True)
class Outcome:
    ok: bool
    gone: bool  # the browser unsubscribed or the subscription expired: forget it
