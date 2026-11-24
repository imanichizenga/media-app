import boto3
import pytest
import redis
from moto import mock_aws

from newsplatform.common.errors import ServiceUnavailable
from newsplatform.integrations import base
from newsplatform.integrations.base import Test, guarded_call, providers
from newsplatform.integrations.models import IntegrationCall
from newsplatform.integrations.providers import audit_anchor, ses, waf

pytestmark = pytest.mark.django_db
SES = {"region": "eu-west-1", "from_email": "news@example.com", "from_name": "News"}


def run(key, config, params=None):
    t = Test(key, lambda s: None)
    providers()[key].test(config, t, params or {})
    return t, {s.key: s.status for s in t.steps}


def test_ses_unverified_then_verified():
    with mock_aws():
        conf = ses.SesConfig(**SES)
        client = boto3.client("sesv2", region_name="eu-west-1")
        import newsplatform.integrations.providers.ses as mod

        class Wrapped:
            exceptions = client.exceptions

            def get_account(self):
                return {"SendingEnabled": True, "ProductionAccessEnabled": True}

            def get_email_identity(self, EmailIdentity):
                return {
                    **client.get_email_identity(EmailIdentity=EmailIdentity),
                    "VerifiedForSendingStatus": True,
                }

            def send_email(self, **kw):
                self.sent = kw
                return {"MessageId": "m-1"}

        w = Wrapped()
        mod_client, mod.client = mod.client, lambda *a, **k: w
        try:
            t, steps = run("aws_ses", conf, {"to": "x@example.com"})
            assert steps == {"account": "passed", "identity": "failed", "send": "skipped"} and not t.passed
            client.create_email_identity(EmailIdentity="example.com")
            t, steps = run("aws_ses", conf, {"to": "x@example.com"})
            assert t.passed and w.sent["FromEmailAddress"] == '"News" <news@example.com>'
        finally:
            mod.client = mod_client


def test_ses_header_injection_refused():
    with pytest.raises(ValueError, match="from_name"):
        ses.SesConfig(**{**SES, "from_name": "x\r\nBcc: a@b.co"})


def test_deliver_says_so_when_unconfigured():
    assert ses.deliver(to="a@b.co", subject="s", text="t") is False


def test_waf_sync_writes_allowlist_and_opens_when_disabled(monkeypatch):
    with mock_aws():
        c = boto3.client("wafv2", region_name="us-east-1")
        ids = {}
        for fam in ("IPV4", "IPV6"):
            ids[fam] = c.create_ip_set(Name=fam, Scope="CLOUDFRONT", IPAddressVersion=fam, Addresses=[])[
                "Summary"
            ]
        conf = waf.WafConfig(
            region="af-south-1",
            ipv4_set_name="IPV4",
            ipv4_set_id=ids["IPV4"]["Id"],
            ipv6_set_name="IPV6",
            ipv6_set_id=ids["IPV6"]["Id"],
        )
        monkeypatch.setattr("newsplatform.integrations.services.get_active", lambda *a: conf)

        def current(fam):
            return set(c.get_ip_set(Name=fam, Scope="CLOUDFRONT", Id=ids[fam]["Id"])["IPSet"]["Addresses"])

        assert waf.push_allowlist(True, ["203.0.113.0/24", "2001:db8::/32"])
        assert current("IPV4") == {"203.0.113.0/24"} and current("IPV6") == {"2001:db8::/32"}
        assert waf.push_allowlist(False, [])
        assert current("IPV4") == set(waf.OPEN[4])
        assert run("aws_waf", conf)[0].passed


def test_anchor_test_detects_a_bucket_without_object_lock():
    with mock_aws():
        s3 = boto3.client("s3", region_name="af-south-1")
        s3.create_bucket(Bucket="plain", CreateBucketConfiguration={"LocationConstraint": "af-south-1"})
        conf = audit_anchor.AnchorConfig(region="af-south-1", bucket="plain")
        _, steps = run("audit_anchor", conf)
        assert steps["lock"] == "failed" and steps["immutable"] == "skipped"


def test_circuit_opens_after_repeated_failures_and_logs_redacted():
    for _ in range(base._FAILS):
        with pytest.raises(ValueError, match="nope"), guarded_call("p", "op"):
            raise ValueError("nope for +255712345678")
    with pytest.raises(ServiceUnavailable), guarded_call("p", "op"):
        pytest.fail("must not run while open")
    assert "+255" not in IntegrationCall.objects.first().detail


def test_breaker_survives_redis_outage(monkeypatch):
    class Down:
        def __getattr__(self, _):
            def boom(*a, **k):
                raise redis.ConnectionError

            return boom

    monkeypatch.setattr(base, "cache", Down)
    with guarded_call("p", "op"):
        pass
    with pytest.raises(ValueError, match="x"), guarded_call("p", "op"):
        raise ValueError("x")


@pytest.mark.parametrize(
    "bad", [{"access_key_id": "AKIA"}, {"role_arn": "nope"}, {"region": "Mars"}, {"extra": 1}]
)
def test_aws_config_validation(bad):
    with pytest.raises(ValueError, match="validation error"):
        audit_anchor.AnchorConfig(**{"region": "af-south-1", "bucket": "abc", **bad})


def test_every_hint_is_also_in_swahili():
    """Found in the source, so a new hint cannot be forgotten."""
    import ast
    from pathlib import Path

    from newsplatform.integrations import base, hints

    root = Path(base.__file__).parents[1]
    wanted = set(base._HINTS.values()) | {"Check credentials, region and network access to AWS."}
    for path in root.rglob("*.py"):
        for node in ast.walk(ast.parse(path.read_text())):
            if (
                isinstance(node, ast.Call)
                and getattr(node.func, "id", "") == "StepFailed"
                and len(node.args) > 1
            ):
                assert isinstance(node.args[1], ast.Constant), f"{path}: a hint must be a plain sentence"
                wanted.add(node.args[1].value)
    assert wanted - set(hints.SW) == set()
