"""The public website and its CDN: told about every published change."""

import time
import uuid
from typing import Any

from pydantic import SecretStr

from newsplatform.integrations.aws import AwsConfig, client, field, whoami
from newsplatform.integrations.base import Provider, StepFailed, Test, register_provider

_MAX_PATHS = 1000  # beyond this a wildcard is cheaper than listing


class WebConfig(AwsConfig):
    host: str = field(
        ..., "Website host", "Anwani ya tovuti", pattern=r"^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$"
    )
    secret: SecretStr = field(..., "Revalidation secret", "Siri ya kuonyesha upya", min_length=32)
    web_distribution_id: str = field(
        "", "Website distribution ID", "Kitambulisho cha usambazaji (tovuti)", pattern=r"^(E[A-Z0-9]{8,20})?$"
    )
    api_distribution_id: str = field(
        "", "API distribution ID", "Kitambulisho cha usambazaji (API)", pattern=r"^(E[A-Z0-9]{8,20})?$"
    )


def _invalidate(config: WebConfig, distribution: str, items: list[str]) -> str:
    wanted = ["/*"] if len(items) > _MAX_PATHS else items
    out = client(config, "cloudfront", "us-east-1").create_invalidation(
        DistributionId=distribution,
        InvalidationBatch={
            "Paths": {"Quantity": len(wanted), "Items": wanted},
            "CallerReference": uuid.uuid4().hex,
        },
    )
    return str(out["Invalidation"]["Id"])


def invalidate(config: WebConfig, tags: list[str], pages: list[str]) -> None:
    """CloudFront purges by path. Lists change with every publication, so they go as prefixes."""
    if config.web_distribution_id and pages:
        _invalidate(config, config.web_distribution_id, sorted({*pages, "/", "/en"}))
    if config.api_distribution_id:
        _invalidate(config, config.api_distribution_id, ["/api/v1/content/*"])


@register_provider
class WebProvider(Provider[WebConfig]):
    key, name, category = "web", "Website and CDN", "delivery"
    description_en = "Refreshes pages the moment something is published."
    description_sw = "Huonyesha upya kurasa mara tu jambo linapochapishwa."
    config_model = WebConfig

    def test(self, config: WebConfig, t: Test, params: dict[str, Any]) -> None:
        from newsplatform.seo.delivery import post_signed

        def revalidate() -> str:
            res = post_signed(config, {"id": uuid.uuid4().hex, "tags": [], "paths": []}, int(time.time()))
            if res.status != 200:
                raise StepFailed(
                    f"The website answered {res.status}.", "Check the host and that it is deployed."
                )
            return "Accepted"

        def tampered() -> str:
            res = post_signed(config, {"id": "x", "tags": [], "paths": []}, int(time.time()) - 3600)
            if res.status not in (401, 403):
                raise StepFailed(
                    f"An hour-old request was answered with {res.status}.", "The website must refuse replays."
                )
            return f"{res.status} as expected"

        t.step("revalidate", "Signed request accepted", "Ombi lililotiwa sahihi limekubaliwa", revalidate)
        t.step("replay", "Old request refused", "Ombi la zamani limekataliwa", tampered, needs="revalidate")
        if config.web_distribution_id or config.api_distribution_id:
            t.step("credentials", "Credentials", "Vitambulisho", lambda: whoami(config))
        for key, ident in (("web", config.web_distribution_id), ("api", config.api_distribution_id)):
            if ident:
                t.step(
                    f"purge_{key}",
                    f"Purge the {key} distribution",
                    f"Futa akiba ya {key}",
                    lambda ident=ident: _invalidate(config, ident, ["/_probe"]),  # type: ignore[misc]
                    needs="credentials",
                )
