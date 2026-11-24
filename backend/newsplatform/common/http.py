"""SSRF-safe outbound HTTP.

The address is validated and dialled in the same step, so DNS rebinding cannot swap it afterwards.
TLS still verifies the original hostname. Redirects and proxy environment variables are ignored.
"""

import ipaddress
import socket
import ssl
from collections.abc import Iterable
from dataclasses import dataclass
from typing import Any

import httpcore
import httpx


class UnsafeDestination(httpx.RequestError):
    pass


class ResponseTooLarge(httpx.RequestError):
    pass


_NAT64 = ipaddress.ip_network("64:ff9b::/96")


def is_public_address(raw: str) -> bool:
    ip = ipaddress.ip_address(raw.split("%")[0])
    if isinstance(ip, ipaddress.IPv6Address):
        if ip.ipv4_mapped:
            ip = ip.ipv4_mapped
        elif ip.sixtofour or ip.teredo or ip in _NAT64:
            return False
    return ip.is_global and not (ip.is_multicast or ip.is_reserved or ip.is_unspecified)


class _SafeBackend(httpcore.SyncBackend):
    def connect_tcp(
        self,
        host: str,
        port: int,
        timeout: float | None = None,
        local_address: str | None = None,
        socket_options: Iterable[Any] | None = None,
    ) -> httpcore.NetworkStream:
        try:
            infos = socket.getaddrinfo(host, port, type=socket.SOCK_STREAM)
        except socket.gaierror as exc:
            raise httpcore.ConnectError(f"DNS lookup failed for {host}") from exc
        addresses = list(dict.fromkeys(str(info[4][0]) for info in infos))
        if not addresses or not all(is_public_address(a) for a in addresses):
            raise UnsafeDestination(f"{host} resolves to a non-public address")
        last: Exception | None = None
        for address in sorted(addresses, key=lambda a: ":" in a):
            try:
                return super().connect_tcp(address, port, timeout, local_address, socket_options)
            except (httpcore.ConnectError, httpcore.ConnectTimeout) as exc:
                last = exc
        raise last or httpcore.ConnectError(host)


@dataclass(frozen=True, slots=True)
class SafeResponse:
    status: int
    headers: httpx.Headers
    body: bytes


def fetch(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    content: bytes | None = None,
    max_bytes: int = 2_000_000,
    timeout: float = 8.0,
) -> SafeResponse:
    parsed = httpx.URL(url)
    if parsed.scheme != "https" or parsed.userinfo or parsed.port not in (None, 443):
        raise UnsafeDestination("Only plain https:// URLs on port 443 are allowed")
    transport = httpx.HTTPTransport()
    transport._pool = httpcore.ConnectionPool(
        ssl_context=ssl.create_default_context(), network_backend=_SafeBackend(), max_connections=1
    )
    with (
        httpx.Client(
            transport=transport,
            follow_redirects=False,
            trust_env=False,
            timeout=httpx.Timeout(timeout, connect=min(timeout, 4.0)),
            headers={"user-agent": "newsplatform/1.0"},
        ) as client,
        client.stream(method, parsed, headers=headers, content=content) as response,
    ):
        chunks, size = [], 0
        for chunk in response.iter_bytes():
            size += len(chunk)
            if size > max_bytes:
                raise ResponseTooLarge(f"Response exceeded {max_bytes} bytes")
            chunks.append(chunk)
        return SafeResponse(response.status_code, response.headers, b"".join(chunks))
