"""Tells search engines what changed (IndexNow). Off until an administrator turns it on."""

import json

import structlog

from newsplatform.common.http import fetch
from newsplatform.integrations.base import guarded_call

log = structlog.get_logger(__name__)
ENDPOINT = "https://api.indexnow.org/indexnow"
_MAX = 10_000


def submit(pages: list[str]) -> None:
    from newsplatform.integrations.providers.web import WebConfig
    from newsplatform.integrations.services import get_active
    from newsplatform.site_config.services import get_seo

    seo = get_seo()[0]
    config = get_active("web", WebConfig)
    if not pages or config is None or not (seo.indexnow and seo.indexnow_key):
        return
    body = {
        "host": config.host,
        "key": seo.indexnow_key,
        "keyLocation": f"https://{config.host}/{seo.indexnow_key}.txt",
        "urlList": [f"https://{config.host}{p}" for p in pages[:_MAX]],
    }
    with guarded_call("web", "indexnow"):
        res = fetch(
            "POST", ENDPOINT, content=json.dumps(body).encode(), headers={"content-type": "application/json"}
        )
        if res.status not in (200, 202):
            raise RuntimeError(f"IndexNow answered {res.status}")
