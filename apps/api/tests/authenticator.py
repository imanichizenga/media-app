"""A minimal software passkey (ES256, "none" attestation) so WebAuthn is verified for real, not mocked."""

import hashlib
import json
import os
import struct

import cbor2
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec

from tests.conftest import ORIGIN, b64


class Authenticator:
    def __init__(self, rp_id: str = "localhost", origin: str = ORIGIN) -> None:
        self.key, self.cred_id, self.count = ec.generate_private_key(ec.SECP256R1()), os.urandom(32), 0
        self.rp_id, self.origin = rp_id, origin

    def _auth_data(self, *, uv: bool, attested: bytes = b"") -> bytes:
        self.count += 1
        flags = 0x01 | (0x04 if uv else 0) | (0x40 if attested else 0)
        return (
            hashlib.sha256(self.rp_id.encode()).digest()
            + bytes([flags])
            + struct.pack(">I", self.count)
            + attested
        )

    def _client_data(self, kind: str, challenge: str) -> bytes:
        return json.dumps({"type": kind, "challenge": challenge, "origin": self.origin}).encode()

    def create(self, options: dict, *, uv: bool = True) -> dict:
        pub = self.key.public_key().public_numbers()
        cose = cbor2.dumps({1: 2, 3: -7, -1: 1, -2: pub.x.to_bytes(32), -3: pub.y.to_bytes(32)})
        attested = bytes(16) + struct.pack(">H", 32) + self.cred_id + cose
        obj = cbor2.dumps(
            {"fmt": "none", "attStmt": {}, "authData": self._auth_data(uv=uv, attested=attested)}
        )
        return self._credential(
            {
                "clientDataJSON": b64(self._client_data("webauthn.create", options["challenge"])),
                "attestationObject": b64(obj),
                "transports": ["internal"],
            }
        )

    def get(self, options: dict, *, uv: bool = True) -> dict:
        data, client = self._auth_data(uv=uv), self._client_data("webauthn.get", options["challenge"])
        sig = self.key.sign(data + hashlib.sha256(client).digest(), ec.ECDSA(hashes.SHA256()))
        return self._credential(
            {
                "clientDataJSON": b64(client),
                "authenticatorData": b64(data),
                "signature": b64(sig),
                "userHandle": None,
            }
        )

    def _credential(self, response: dict) -> dict:
        return {
            "id": b64(self.cred_id),
            "rawId": b64(self.cred_id),
            "type": "public-key",
            "response": response,
            "clientExtensionResults": {},
            "authenticatorAttachment": "platform",
        }
