import json

import boto3
import pytest
from moto import mock_aws

from newsplatform.audit.models import AuditEntry
from newsplatform.common import crypto
from newsplatform.common.http import SafeResponse
from newsplatform.integrations import services
from newsplatform.integrations.base import providers
from newsplatform.integrations.models import IntegrationConfig, IntegrationTestRun, IntegrationVersion
from newsplatform.integrations.providers import s3 as s3_mod
from newsplatform.integrations.providers.s3 import S3Config

pytestmark = pytest.mark.django_db
SECRET = "wJalrXUtnFEMIK7MDENGbPxRfiCYSUPERSECRET"
FIELDS = {
    "region": "af-south-1",
    "bucket": "news-media",
    "cdn_domain": "cdn.example.com",
    "distribution_id": "E1ABCDEFGHIJKL",
    "access_key_id": "AKIAIOSFODNN7EXAMPLE",
    "role_arn": "",
}


def save(api, base=0, secrets=None, **over):
    return api.put(
        "integrations/aws_s3",
        {
            "base_number": base,
            "fields_": {**FIELDS, **over},
            "secrets": {"secret_access_key": SECRET} if secrets is None else secrets,
        },
    )


@pytest.fixture
def run_now(django_capture_on_commit_callbacks):
    def go(fn):
        with django_capture_on_commit_callbacks(execute=True):
            return fn()

    return go


def passed(number=1):
    v = IntegrationVersion.objects.get(number=number)
    IntegrationTestRun.objects.create(version=v, status="passed", finished_at=v.created_at)


def test_secret_never_leaves_the_server(admin_api):
    _, api = admin_api()
    res = save(api)
    assert res.status_code == 200, res.content
    assert SECRET not in res.content.decode()
    assert res.json()["latest"]["secret_hints"] == {"secret_access_key": "••••CRET"}
    assert SECRET not in api.get("integrations/aws_s3").content.decode()
    assert SECRET not in json.dumps(
        list(IntegrationVersion.objects.values("fields", "secrets", "secret_hints"))
    )
    assert SECRET not in str(list(AuditEntry.objects.values("before", "after")))


def test_invalid_config_error_does_not_echo_the_secret(admin_api):
    _, api = admin_api()
    res = save(api, bucket="Not A Bucket")
    assert res.status_code == 400 and SECRET not in res.content.decode()


def test_omitted_secret_is_kept_and_null_clears_it(admin_api):
    _, api = admin_api()
    save(api)
    assert save(api, 1, {}, bucket="other-bucket").status_code == 200
    v2 = IntegrationVersion.objects.select_related("config").get(number=2)
    assert services.build(v2).secret_access_key.get_secret_value() == SECRET
    assert save(api, 2, {"secret_access_key": None}, access_key_id="").status_code == 200
    assert IntegrationVersion.objects.get(number=3).secrets is None


def test_secret_inside_plain_fields_is_refused(admin_api):
    _, api = admin_api()
    assert save(api, 0, {}, secret_access_key=SECRET).status_code == 400


def test_ciphertext_is_bound_to_its_record(admin_api):
    _, api = admin_api()
    save(api)
    v = IntegrationVersion.objects.select_related("config").get()
    v.config = IntegrationConfig.objects.create(provider="aws_ses", environment="test")
    with pytest.raises(Exception):  # noqa: B017
        services._secrets(v)


def test_stale_edit_is_refused(admin_api):
    _, api = admin_api()
    save(api)
    assert save(api, 0).json()["code"] == "stale_version"


def test_activation_needs_a_pass_on_this_exact_version(admin_api):
    _, api = admin_api()
    save(api)
    assert api.post("integrations/aws_s3/versions/1/activate").json()["code"] == "test_not_passed"
    passed(1)
    save(api, 1, {}, bucket="other-bucket")
    assert api.post("integrations/aws_s3/versions/2/activate").json()["code"] == "test_not_passed"
    assert api.post("integrations/aws_s3/versions/1/activate").json()["code"] == "stale_version"


def test_later_failure_revokes_an_earlier_pass(admin_api):
    _, api = admin_api()
    save(api)
    passed(1)
    v = IntegrationVersion.objects.get()
    IntegrationTestRun.objects.create(version=v, status="failed", finished_at=v.created_at)
    assert api.post("integrations/aws_s3/versions/1/activate").json()["code"] == "test_not_passed"


def test_override_is_super_admin_only_and_logged(admin_api):
    _, admin = admin_api("admin")
    save(admin)
    body = {"override_reason": "CDN is still propagating"}
    assert admin.post("integrations/aws_s3/versions/1/activate", body).status_code == 403
    _, boss = admin_api()
    assert boss.post("integrations/aws_s3/versions/1/activate", {"override_reason": "meh"}).status_code == 400
    assert boss.post("integrations/aws_s3/versions/1/activate", body).status_code == 200
    assert IntegrationConfig.objects.get().status == "failing"
    assert AuditEntry.objects.get(action="integration.activated").reason == body["override_reason"]


def test_runtime_config_follows_activation(admin_api, run_now):
    _, api = admin_api()
    save(api)
    assert services.get_active("aws_s3", S3Config) is None
    passed(1)
    run_now(lambda: api.post("integrations/aws_s3/versions/1/activate"))
    assert services.get_active("aws_s3", S3Config).bucket == "news-media"


def test_permissions(admin_api):
    _, analyst = admin_api("analyst")
    assert analyst.get("integrations").status_code == 403
    assert save(analyst).status_code == 403


# ---- the S3 test itself ---------------------------------------------------------------------------------
@pytest.fixture
def aws(monkeypatch):
    with mock_aws():
        s3 = boto3.client("s3", region_name="af-south-1")
        s3.create_bucket(Bucket="news-media", CreateBucketConfiguration={"LocationConstraint": "af-south-1"})
        bpa = dict.fromkeys(s3_mod._BPA, True)
        s3.put_public_access_block(Bucket="news-media", PublicAccessBlockConfiguration=bpa)
        real, cf = s3_mod.client, {"oac": "E2OAC"}

        class CloudFront:
            def get_distribution_config(self, Id):
                return {
                    "DistributionConfig": {
                        "Origins": {
                            "Items": [
                                {
                                    "DomainName": "news-media.s3.af-south-1.amazonaws.com",
                                    "OriginAccessControlId": cf["oac"],
                                }
                            ]
                        }
                    }
                }

        monkeypatch.setattr(
            s3_mod, "client", lambda c, svc, r=None: CloudFront() if svc == "cloudfront" else real(c, svc, r)
        )

        def fetch(method, url, **kw):
            if "cdn.example.com" in url:
                key = url.split("cdn.example.com/")[1]
                body = s3.get_object(Bucket="news-media", Key=key)["Body"].read()
                return SafeResponse(cf.get("cdn", 200), {}, body)
            return SafeResponse(cf.get("direct", 403), {}, b"")

        monkeypatch.setattr(s3_mod, "fetch", fetch)
        yield s3, cf


def run_test(api, run_now):
    res = run_now(lambda: api.post("integrations/aws_s3/versions/1/test", {"params": {}}))
    assert res.status_code == 202, res.content
    run = api.get(f"integrations/runs/{res.json()['id']}").json()
    return run["status"], {s["key"]: s["status"] for s in run["steps"]}, run


def test_s3_all_green(admin_api, aws, run_now):
    _, api = admin_api()
    save(api)
    status, steps, _ = run_test(api, run_now)
    assert status == "passed", steps
    assert list(steps) == [
        "load",
        "credentials",
        "put",
        "get",
        "block_public",
        "oac",
        "cdn",
        "direct_denied",
        "delete",
    ]
    assert "Contents" not in aws[0].list_objects_v2(Bucket="news-media")


@pytest.mark.parametrize(
    ("break_it", "step"),
    [
        (lambda s3, cf: s3.delete_public_access_block(Bucket="news-media"), "block_public"),
        (
            lambda s3, cf: s3.put_public_access_block(
                Bucket="news-media",
                PublicAccessBlockConfiguration={
                    "BlockPublicAcls": True,
                    "IgnorePublicAcls": True,
                    "BlockPublicPolicy": True,
                    "RestrictPublicBuckets": False,
                },
            ),
            "block_public",
        ),
        (lambda s3, cf: cf.update(oac=""), "oac"),
        (lambda s3, cf: cf.update(cdn=403), "cdn"),
        (lambda s3, cf: cf.update(direct=200), "direct_denied"),
    ],
)
def test_s3_reports_the_exact_failure_and_still_cleans_up(admin_api, aws, run_now, break_it, step):
    _, api = admin_api()
    save(api)
    break_it(*aws)
    status, steps, run = run_test(api, run_now)
    assert status == "failed"
    assert [k for k, v in steps.items() if v == "failed"] == [step]
    assert steps["delete"] == "passed"
    assert SECRET not in json.dumps(run)
    assert api.post("integrations/aws_s3/versions/1/activate").json()["code"] == "test_not_passed"


def test_s3_missing_bucket_skips_dependents(admin_api, aws, run_now):
    _, api = admin_api()
    save(api, bucket="no-such-bucket")
    status, steps, run = run_test(api, run_now)
    assert status == "failed" and steps["put"] == "failed"
    assert steps["get"] == steps["cdn"] == steps["delete"] == "skipped"
    assert next(s for s in run["steps"] if s["key"] == "put")["remediation"]


def test_emulator_can_never_pass(admin_api, aws, run_now, settings):
    _, api = admin_api()
    save(api)
    settings.AWS_ENDPOINT_URL = ""
    from newsplatform.integrations.base import Test

    t = Test("aws_s3", lambda s: None)
    settings.AWS_ENDPOINT_URL = "http://localhost:4566"
    providers()["aws_s3"].test(S3Config(**{k: v for k, v in FIELDS.items() if k != "access_key_id"}), t, {})
    assert not t.passed


def test_one_test_at_a_time(admin_api):
    _, api = admin_api()
    save(api)
    IntegrationTestRun.objects.create(version=IntegrationVersion.objects.get(), status="running")
    assert api.post("integrations/aws_s3/versions/1/test", {"params": {}}).json()["code"] == "test_running"


def test_redelivered_task_does_not_rerun(admin_api):
    _, api = admin_api()
    save(api)
    run = IntegrationTestRun.objects.create(version=IntegrationVersion.objects.get(), status="passed")
    services.execute_test(str(run.pk))
    run.refresh_from_db()
    assert run.steps == []


# ---- envelope encryption --------------------------------------------------------------------------------
def test_kms_round_trip_and_context_binding(settings, monkeypatch):
    with mock_aws():
        arn = boto3.client("kms", region_name="af-south-1").create_key()["KeyMetadata"]["Arn"]
        provider = crypto.KmsKeyProvider(arn)
        monkeypatch.setattr(crypto, "key_provider", lambda: provider)
        env = crypto.encrypt(b"siri", {"purpose": "a"})
        assert crypto.decrypt(env, {"purpose": "a"}) == b"siri"
        with pytest.raises(Exception):  # noqa: B017
            crypto.decrypt(env, {"purpose": "b"})


def test_every_record_gets_its_own_key():
    a, b = crypto.encrypt(b"x", {"p": "1"}), crypto.encrypt(b"x", {"p": "1"})
    assert a["k"] != b["k"] and a["c"] != b["c"]


# ---- audit anchor ---------------------------------------------------------------------------------------
def test_anchor_writes_locked_object_and_worm_verification_catches_rewrites(admin_api, tamper, monkeypatch):
    from newsplatform.integrations.providers import audit_anchor as mod

    admin_api()
    with mock_aws():
        s3 = boto3.client("s3", region_name="af-south-1")
        s3.create_bucket(
            Bucket="audit-worm",
            ObjectLockEnabledForBucket=True,
            CreateBucketConfiguration={"LocationConstraint": "af-south-1"},
        )
        conf = mod.AnchorConfig(region="af-south-1", bucket="audit-worm", retention_days=30)
        monkeypatch.setattr(mod, "_active", lambda: conf)
        anchor = mod.anchor_head()
        assert anchor is not None and mod.anchor_head() is None
        got = s3.get_object(Bucket="audit-worm", Key=anchor.key)
        assert got["ObjectLockMode"] == "COMPLIANCE"
        assert mod.verify_against_worm() == (1, [])
        tamper("UPDATE audit_auditentry SET hash=%s WHERE seq=%s", "f" * 64, anchor.seq)
        checked, problems = mod.verify_against_worm()
        assert checked == 1 and len(problems) == 1


def test_waf_open_set_avoids_the_forbidden_slash_zero():
    import ipaddress

    from newsplatform.integrations.providers.waf import OPEN

    for family, nets in OPEN.items():
        merged = list(ipaddress.collapse_addresses(ipaddress.ip_network(n) for n in nets))
        assert [n.prefixlen for n in merged] == [0] and merged[0].version == family
        assert all(not n.endswith("/0") for n in nets)
