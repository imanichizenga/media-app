"""A WebSocket test client. `channels.testing` would bring Daphne and Twisted along."""

import json
from typing import Any

from asgiref.testing import ApplicationCommunicator


class WebSocket(ApplicationCommunicator):
    def __init__(self, application: Any, path: str, headers: list[tuple[bytes, bytes]], ip: str) -> None:
        super().__init__(
            application,
            {
                "type": "websocket",
                "path": path,
                "query_string": b"",
                "headers": headers,
                "subprotocols": [],
                "client": (ip, 1),
            },
        )

    async def connect(self) -> bool:
        await self.send_input({"type": "websocket.connect"})
        return (await self.receive_output(5))["type"] == "websocket.accept"

    async def send_text(self, text: str) -> None:
        await self.send_input({"type": "websocket.receive", "text": text})

    async def send_bytes(self, data: bytes) -> None:
        await self.send_input({"type": "websocket.receive", "bytes": data})

    async def send_json(self, data: Any) -> None:
        await self.send_text(json.dumps(data))

    async def receive_json(self) -> Any:
        out = await self.receive_output(5)
        assert out["type"] == "websocket.send", out
        return json.loads(out["text"])

    async def closed_with(self) -> int:
        out = await self.receive_output(5)
        assert out["type"] == "websocket.close", out
        code: int = out["code"]
        return code

    async def disconnect(self) -> None:
        await self.send_input({"type": "websocket.disconnect", "code": 1000})
        await self.wait(5)
