"""What tells the website and the CDN that something changed."""

import hashlib
import hmac
import json

import pytest
from celery.exceptions import Retry

from newsplatform.common.http import SafeResponse
from newsplatform.content import tasks
from newsplatform.integrations.base import Test
from newsplatform.integrations.providers import web
from newsplatform.seo import delivery

pytestmark = pytest.mark.django_db
SECRET = "s" * 40


@pytest.fixture
def config():
    return web.WebConfig(
        region="af-south-1",
        host="www.example.com",
        secret=SECRET,
        web_distribution_id="EWEB1234567",
        api_distribution_id="EAPI1234567",
    )


@pytest.fixture
def world(monkeypatch, config):
    """The website and CloudFront, both recording what they were told."""
    done: list[tuple[str, object]] = []
    state = {"status": 200}

    def fetch(method, url, content, headers):
        done.append(("website", (url, content, headers)))
        return SafeResponse(state["status"], {}, b"")

    class CloudFront:
        def create_invalidation(self, DistributionId, InvalidationBatch):
            done.append((DistributionId, InvalidationBatch["Paths"]["Items"]))
            return {"Invalidation": {"Id": "I1"}}

    monkeypatch.setattr(delivery, "fetch", fetch)
    monkeypatch.setattr(delivery, "get_active", lambda key, model: config)
    monkeypatch.setattr(web, "client", lambda *a: CloudFront())
    monkeypatch.setattr(web, "whoami", lambda c: "Account 1")
    return done, state


def test_the_website_hears_first_then_the_cdn(world):
    done, _ = world
    delivery.purge(["post-1", "latest"], ["/habari/a"])
    assert [who for who, _ in done] == ["website", "EWEB1234567", "EAPI1234567"]
    url, content, headers = done[0][1]
    assert url == "https://www.example.com/api/revalidate"
    assert json.loads(content)["tags"] == ["post-1", "latest"]
    expected = hmac.new(
        SECRET.encode(), f"{headers['x-timestamp']}.".encode() + content, hashlib.sha256
    ).hexdigest()
    assert headers["x-signature"] == expected
    assert done[1][1] == ["/", "/en", "/habari/a"]
    assert done[2][1] == ["/api/v1/content/*"]


def test_a_broken_website_does_not_keep_the_cdn_stale(world):
    done, state = world
    state["status"] = 500
    with pytest.raises(RuntimeError, match="500"):
        delivery.purge(["post-1"], ["/habari/a"])
    assert [who for who, _ in done] == ["website", "EWEB1234567", "EAPI1234567"]


def test_a_failed_purge_is_tried_again(world):
    _, state = world
    state["status"] = 500
    with pytest.raises(Retry):
        tasks.announce.apply(args=[["post-1"], ["/habari/a"]], throw=True)
    assert tasks.announce.max_retries == 6


def test_many_pages_go_in_pieces_and_tags_once(world):
    done, _ = world
    delivery.purge(["category-1"], [f"/habari/{i}" for i in range(250)])
    calls = [json.loads(c[1]) for who, c in done if who == "website"]
    assert [len(c["paths"]) for c in calls] == [100, 100, 50]
    assert [c["tags"] for c in calls] == [["category-1"], [], []]


def test_beyond_a_thousand_pages_one_wildcard_is_cheaper(world, config):
    done, _ = world
    web.invalidate(config, [], [f"/habari/{i}" for i in range(1500)])
    assert done[0] == ("EWEB1234567", ["/*"])


def test_nothing_happens_without_a_website(monkeypatch):
    monkeypatch.setattr(delivery, "get_active", lambda key, model: None)
    monkeypatch.setattr(delivery, "fetch", lambda *a, **k: pytest.fail("called"))
    delivery.purge(["latest"], [])


@pytest.mark.usefixtures("world")
def test_the_button_demands_that_old_requests_are_refused(config):
    t = Test("web", lambda steps: None)
    web.WebProvider().test(config, t, {})
    steps = {s.key: s.status for s in t.steps}
    assert steps["revalidate"] == "passed"
    assert steps["replay"] == "failed"  # this website accepts an hour-old request
    assert steps["purge_web"] == steps["purge_api"] == "passed"
