import ipaddress
from typing import Any

from newsplatform.integrations.aws import AwsConfig, client, field, whoami
from newsplatform.integrations.base import Provider, Test, guarded_call, register_provider

# AWS WAF rejects /0, so "allow everyone" is two halves of each address space.
OPEN = {4: ["0.0.0.0/1", "128.0.0.0/1"], 6: ["::/1", "8000::/1"]}


class WafConfig(AwsConfig):
    ipv4_set_name: str = field(..., "IPv4 set name", "Jina la seti ya IPv4")
    ipv4_set_id: str = field(..., "IPv4 set ID", "Kitambulisho cha seti ya IPv4")
    ipv6_set_name: str = field(..., "IPv6 set name", "Jina la seti ya IPv6")
    ipv6_set_id: str = field(..., "IPv6 set ID", "Kitambulisho cha seti ya IPv6")


def _sets(config: WafConfig) -> list[tuple[int, dict[str, str]]]:
    return [
        (4, {"Name": config.ipv4_set_name, "Id": config.ipv4_set_id, "Scope": "CLOUDFRONT"}),
        (6, {"Name": config.ipv6_set_name, "Id": config.ipv6_set_id, "Scope": "CLOUDFRONT"}),
    ]


def push_allowlist(enabled: bool, cidrs: list[str]) -> bool:
    from newsplatform.integrations.services import get_active

    config = get_active("aws_waf", WafConfig)
    if config is None:
        return False
    waf = client(config, "wafv2", "us-east-1")  # CLOUDFRONT-scope sets live only in us-east-1
    for family, ref in _sets(config):
        wanted = [c for c in cidrs if ipaddress.ip_network(c).version == family] if enabled else OPEN[family]
        with guarded_call("aws_waf", "update_ip_set"):
            current = waf.get_ip_set(**ref)
            if set(current["IPSet"]["Addresses"]) != set(wanted):
                waf.update_ip_set(**ref, Addresses=wanted, LockToken=current["LockToken"])
    return True


@register_provider
class WafProvider(Provider[WafConfig]):
    key, name, category = "aws_waf", "AWS WAF allowlist", "security"
    description_en = "Enforces the admin IP allowlist at the network edge."
    description_sw = "Hutekeleza orodha ya IP zinazoruhusiwa kwenye mipaka ya mtandao."
    config_model = WafConfig

    def test(self, config: WafConfig, t: Test, params: dict[str, Any]) -> None:
        t.step("credentials", "Credentials", "Vitambulisho", lambda: whoami(config))
        for family, ref in _sets(config):

            def read(ref: dict[str, str] = ref) -> str:
                got = client(config, "wafv2", "us-east-1").get_ip_set(**ref)
                return f"{len(got['IPSet']['Addresses'])} networks"

            t.step(
                f"ipv{family}",
                f"IPv{family} set reachable",
                f"Seti ya IPv{family} inafikika",
                read,
                needs="credentials",
            )
