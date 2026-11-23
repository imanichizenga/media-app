"""Envelope encryption. A fresh AES-256-GCM data key per record, wrapped by KMS (or a local key in dev).

The encryption context binds a ciphertext to its record: copying it to another row fails to decrypt.
"""

import base64
import os
from functools import lru_cache
from typing import Any, Protocol

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from django.conf import settings

from newsplatform.common.canonical import canonical_json

Ctx = dict[str, str]


class KeyProvider(Protocol):
    name: str

    def generate(self, ctx: Ctx) -> tuple[bytes, bytes]: ...
    def unwrap(self, wrapped: bytes, ctx: Ctx) -> bytes: ...


class KmsKeyProvider:
    name = "kms"

    def __init__(self, key_arn: str) -> None:
        import boto3
        from botocore.config import Config

        self._arn = key_arn
        self._kms = boto3.client(
            "kms",
            region_name=settings.AWS_REGION,
            config=Config(connect_timeout=2, read_timeout=5, retries={"max_attempts": 3, "mode": "standard"}),
        )

    def generate(self, ctx: Ctx) -> tuple[bytes, bytes]:
        out: Any = self._kms.generate_data_key(KeyId=self._arn, KeySpec="AES_256", EncryptionContext=ctx)
        return out["Plaintext"], out["CiphertextBlob"]

    def unwrap(self, wrapped: bytes, ctx: Ctx) -> bytes:
        out = self._kms.decrypt(CiphertextBlob=wrapped, EncryptionContext=ctx, KeyId=self._arn)
        return out["Plaintext"]


class LocalKeyProvider:
    """Development and tests only; a system check refuses it in staging and prod."""

    name = "local"

    def __init__(self, secret: str) -> None:
        self._kek = HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=b"newsplatform.kek.v1").derive(
            secret.encode()
        )

    def generate(self, ctx: Ctx) -> tuple[bytes, bytes]:
        key, nonce = AESGCM.generate_key(256), os.urandom(12)
        return key, nonce + AESGCM(self._kek).encrypt(nonce, key, canonical_json(ctx))

    def unwrap(self, wrapped: bytes, ctx: Ctx) -> bytes:
        return AESGCM(self._kek).decrypt(wrapped[:12], wrapped[12:], canonical_json(ctx))


@lru_cache
def key_provider() -> KeyProvider:
    if settings.KMS_KEY_ARN:
        return KmsKeyProvider(settings.KMS_KEY_ARN)
    if not settings.LOCAL_ENCRYPTION_KEY:
        raise RuntimeError("No encryption key is configured")
    return LocalKeyProvider(settings.LOCAL_ENCRYPTION_KEY)


def _b64(raw: bytes) -> str:
    return base64.b64encode(raw).decode()


def encrypt(plaintext: bytes, ctx: Ctx) -> dict[str, Any]:
    provider = key_provider()
    key, wrapped = provider.generate(ctx)
    nonce = os.urandom(12)
    ct = AESGCM(key).encrypt(nonce, plaintext, canonical_json(ctx))
    return {"v": 1, "kp": provider.name, "k": _b64(wrapped), "n": _b64(nonce), "c": _b64(ct)}


def decrypt(envelope: dict[str, Any], ctx: Ctx) -> bytes:
    provider = key_provider()
    if envelope.get("v") != 1 or envelope.get("kp") != provider.name:
        raise ValueError("Envelope was written by a different key provider")
    key = provider.unwrap(base64.b64decode(envelope["k"]), ctx)
    return AESGCM(key).decrypt(
        base64.b64decode(envelope["n"]), base64.b64decode(envelope["c"]), canonical_json(ctx)
    )
