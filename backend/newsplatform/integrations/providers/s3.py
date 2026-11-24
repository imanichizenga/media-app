import os
import uuid
from typing import Any

from django.conf import settings

from newsplatform.common.http import fetch
from newsplatform.integrations.aws import AwsConfig, client, field, whoami
from newsplatform.integrations.base import Provider, StepFailed, Test, register_provider

_BPA = ("BlockPublicAcls", "IgnorePublicAcls", "BlockPublicPolicy", "RestrictPublicBuckets")


class S3Config(AwsConfig):
    bucket: str = field(..., "Media bucket", "Ndoo ya media", pattern=r"^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$")
    cdn_domain: str = field(
        ...,
        "CloudFront domain",
        "Kikoa cha CloudFront",
        pattern=r"^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$",
    )
    distribution_id: str = field(
        ..., "CloudFront distribution ID", "Kitambulisho cha CloudFront", pattern=r"^E[A-Z0-9]{8,20}$"
    )


@register_provider
class S3Provider(Provider[S3Config]):
    key, name, category = "aws_s3", "Amazon S3 + CloudFront", "media"
    description_en = "Private media storage, delivered only through CloudFront."
    description_sw = "Hifadhi binafsi ya media, hutolewa kupitia CloudFront pekee."
    config_model = S3Config

    def test(self, config: S3Config, t: Test, params: dict[str, Any]) -> None:
        # Under media/, so the probe takes the same path and policies as real assets.
        key, body = f"media/_probe/{uuid.uuid4()}.bin", os.urandom(64)
        box: dict[str, Any] = {}

        def put() -> str:
            box["s3"].put_object(
                Bucket=config.bucket,
                Key=key,
                Body=body,
                ContentType="application/octet-stream",
                CacheControl="no-store",
            )
            return key

        def get() -> str:
            got = box["s3"].get_object(Bucket=config.bucket, Key=key)["Body"].read()
            if got != body:
                raise StepFailed("The bytes read back differ from the bytes written.")
            return f"{len(got)} bytes verified"

        def credentials() -> str:
            box["s3"] = client(config, "s3")
            return whoami(config)

        def block_public() -> str:
            conf = box["s3"].get_public_access_block(Bucket=config.bucket)["PublicAccessBlockConfiguration"]
            if off := [k for k in _BPA if not conf.get(k)]:
                raise StepFailed(
                    f"Not enabled: {', '.join(off)}", "Enable all four Block Public Access settings."
                )
            return "All four settings are on"

        def oac() -> str:
            dist = client(config, "cloudfront", "us-east-1").get_distribution_config(
                Id=config.distribution_id
            )
            origins = dist["DistributionConfig"]["Origins"]["Items"]
            mine = [o for o in origins if o["DomainName"].startswith(f"{config.bucket}.s3")]
            if not mine:
                raise StepFailed(
                    "No origin of this distribution points at the bucket.", "Add the bucket as an S3 origin."
                )
            if not mine[0].get("OriginAccessControlId"):
                raise StepFailed(
                    "The S3 origin has no Origin Access Control.", "Attach an OAC that always signs requests."
                )
            return "Origin Access Control attached"

        def through_cdn() -> str:
            res = fetch("GET", f"https://{config.cdn_domain}/{key}")
            if res.status != 200 or res.body != body:
                raise StepFailed(
                    f"CloudFront returned {res.status}.",
                    "Check the bucket policy allows this distribution and the domain is deployed.",
                )
            return f"200 via {res.headers.get('x-amz-cf-pop', 'CloudFront')}"

        def direct_denied() -> str:
            res = fetch("GET", f"https://{config.bucket}.s3.{config.region}.amazonaws.com/{key}")
            if res.status != 403:
                raise StepFailed(
                    f"Anonymous S3 access returned {res.status}, expected 403.",
                    "The bucket may be public. Remove public policies immediately.",
                )
            return "403 as expected"

        t.step("credentials", "Credentials", "Vitambulisho", credentials)
        t.step("put", "Write probe object", "Andika faili la jaribio", put, needs="credentials")
        t.step("get", "Read it back", "Lisome tena", get, needs="put")
        t.step(
            "block_public", "Block Public Access", "Zuia ufikiaji wa umma", block_public, needs="credentials"
        )
        t.step("oac", "Origin Access Control", "Udhibiti wa chanzo (OAC)", oac, needs="credentials")
        # An emulator has no CDN. Failing here is correct: it must never look like a verified setup.
        if settings.AWS_ENDPOINT_URL:
            t.step("cdn", "Fetch through CloudFront", "Pata kupitia CloudFront", _no_cdn, needs="put")
        else:
            t.step("cdn", "Fetch through CloudFront", "Pata kupitia CloudFront", through_cdn, needs="put")
            t.step(
                "direct_denied",
                "Direct access is denied",
                "Ufikiaji wa moja kwa moja umezuiwa",
                direct_denied,
                needs="put",
            )
        t.step(
            "delete",
            "Delete probe object",
            "Futa faili la jaribio",
            lambda: str(box["s3"].delete_object(Bucket=config.bucket, Key=key) and "Deleted"),
            needs="put",
        )


def _no_cdn() -> str:
    raise StepFailed(
        "AWS is emulated here, so CloudFront cannot be verified.", "Run this test against real AWS."
    )
