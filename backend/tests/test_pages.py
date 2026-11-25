"""The publisher's own pages: revisions, both languages, what readers get, and what search engines are told."""

import json
from datetime import timedelta

import pytest
from django.test import Client
from django.utils import timezone

from newsplatform.audit.models import AuditEntry
from newsplatform.common.errors import Conflict, DomainError, Forbidden
from newsplatform.common.http import SafeResponse
from newsplatform.content import tasks
from newsplatform.content.models import Publication
from newsplatform.integrations import services as integrations
from newsplatform.integrations.providers.web import WebConfig
from newsplatform.pages import services
from newsplatform.pages.models import PageRevision
from newsplatform.seo import indexnow, paths
from newsplatform.site_config.services import update_section
from tests import factories as f

pytestmark = pytest.mark.django_db


def text(title: str, words: str = "Maneno"):
    return {
        "title": title,
        "summary": "",
        "body": {
            "version": 1,
            "blocks": [
                {"type": "paragraph", "id": "a1b2c3d4", "content": [{"type": "text", "text": words}]},
            ],
        },
    }


BOTH = {"sw": text("Faragha"), "en": text("Privacy")}


@pytest.fixture
def told(monkeypatch):
    out: list[tuple[list[str], list[str]]] = []
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: out.append((tags, pages)))
    return out


@pytest.fixture
def editor(make_staff):
    return make_staff("editor_in_chief")


@pytest.fixture
def public(settings):
    settings.ROOT_URLCONF = "config.urls_public"
    settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "IpAllowlist" not in m]
    return lambda path: Client().get(f"/api/v1/{path}")


def test_a_page_is_public_only_when_published(editor, told, public, django_capture_on_commit_callbacks):
    services.save(actor=editor, key="privacy", version=0, texts=BOTH)
    assert public("content/pages/privacy").status_code == 404
    assert public("content/pages").json() == {"results": []}
    with django_capture_on_commit_callbacks(execute=True):
        services.publish(actor=editor, key="privacy", number=1)
    res = public("content/pages/privacy?locale=en")
    assert res.status_code == 200
    body = res.json()
    assert (body["title"], body["path"]) == ("Privacy", "/en/privacy")
    assert body["translations"] == [{"locale": "sw", "path": "/privacy"}]
    assert "page-privacy" in res["Surrogate-Key"]
    assert public("content/pages").json()["results"][0]["path"] == "/privacy"
    assert told == [(["pages", "page-privacy"], ["/privacy", "/en/privacy"])]


def test_saving_changes_nothing_for_readers_and_going_back_is_publishing_an_older_revision(
    editor, told, public
):
    services.save(actor=editor, key="terms", version=0, texts=BOTH)
    services.publish(actor=editor, key="terms", number=1)
    services.save(actor=editor, key="terms", version=1, texts={**BOTH, "sw": text("Masharti mapya")})
    assert public("content/pages/terms").json()["title"] == "Faragha"
    services.publish(actor=editor, key="terms", number=2)
    assert public("content/pages/terms").json()["title"] == "Masharti mapya"
    services.publish(actor=editor, key="terms", number=1)
    assert public("content/pages/terms").json()["title"] == "Faragha"
    assert [r.number for r in PageRevision.objects.all()] == [2, 1]
    actions = list(AuditEntry.objects.filter(action__startswith="page.").values_list("action", flat=True))
    assert actions.count("page.published") == 3


def test_both_languages_or_nothing(editor, told):
    services.save(actor=editor, key="about", version=0, texts={"sw": text("Kuhusu")})
    with pytest.raises(DomainError) as e:
        services.publish(actor=editor, key="about", number=1)
    assert e.value.extra["missing"] == ["en.title", "en.body"]


def test_two_editors_do_not_overwrite_each_other(editor, told):
    services.save(actor=editor, key="about", version=0, texts=BOTH)
    with pytest.raises(Conflict):
        services.save(actor=editor, key="about", version=0, texts=BOTH)


def test_a_body_is_content_like_any_other(editor, told):
    bad = {**BOTH["sw"], "body": {"version": 1, "blocks": [{"type": "html", "id": "x", "html": "<script>"}]}}
    with pytest.raises(DomainError):
        services.save(actor=editor, key="about", version=0, texts={"sw": bad})


def test_a_journalist_may_not(make_staff, told):
    with pytest.raises(Forbidden):
        services.save(actor=make_staff("journalist"), key="about", version=0, texts=BOTH)


def test_withdrawn_is_gone(editor, told, public):
    services.save(actor=editor, key="contact", version=0, texts=BOTH)
    services.publish(actor=editor, key="contact", number=1)
    services.withdraw(actor=editor, key="contact")
    assert public("content/pages/contact").status_code == 404


def test_the_console_saves_publishes_and_lists(admin_api, told):
    _, api = admin_api("super_admin")
    res = api.put("pages/privacy", {"version": 0, "texts": BOTH, "note": "Toleo la kwanza"})
    assert res.status_code == 200, res.content
    assert res.json()["missing"] == []
    res = api.post("pages/privacy/publish", {"number": 1})
    assert res.status_code == 200, res.content
    assert res.json()["published_number"] == 1
    assert res.json()["revisions"][0]["is_published"] is True
    assert api.get("pages/privacy/revisions/1").json()["texts"]["en"]["title"] == "Privacy"
    listed = api.get("pages").json()
    assert [p["key"] for p in listed] == [
        "about", "editorial-policy", "corrections", "contact", "privacy", "terms",
    ]  # fmt: skip
    assert api.get("pages/nothing").status_code == 404
    assert api.delete("pages/privacy/publish").json()["published_number"] is None


def test_every_page_address_is_reserved():
    from newsplatform.pages.models import PageKey

    assert set(PageKey.values) <= paths.RESERVED


# ---- sitemaps -----------------------------------------------------------------
@pytest.fixture
def stories(editor, told):
    cat = f.category("habari")
    rows = [f.go(editor, f.post(editor, cat, f"Kichwa {i}"), "publish") for i in range(3)]
    old = Publication.objects.filter(post=rows[2])
    old.update(published_at=timezone.now() - timedelta(days=40))
    return rows


def test_the_news_sitemap_holds_two_days_and_the_index_every_month(stories, public):
    news = public("content/sitemap/news").json()["results"]
    assert len(news) == 2
    assert {"path", "headline", "locale", "published_at", "image"} <= set(news[0])
    index = public("content/sitemap").json()["months"]
    assert sum(m["count"] for m in index) == 3
    assert len(index) == 2
    for month in index:
        assert len(public(f"content/sitemap/{month['month']}").json()["results"]) == month["count"]
    assert public("content/sitemap/2019-01").status_code == 404
    assert public("content/sitemap/2026-13").status_code == 404


def test_sitemaps_cost_the_same_however_many_stories(stories, public, django_assert_max_num_queries):
    with django_assert_max_num_queries(2):
        public("content/sitemap/news")
    with django_assert_max_num_queries(2):
        public("content/sitemap")


# ---- search engines -------------------------------------------------------------
KEY = "a" * 32


@pytest.fixture
def engine(monkeypatch):
    sent: list[dict] = []
    config = WebConfig(region="af-south-1", host="www.example.com", secret="s" * 40)
    monkeypatch.setattr(integrations, "get_active", lambda key, model: config)
    state = {"status": 202}

    def fetch(method, url, content, headers):
        sent.append({"url": url, **json.loads(content)})
        return SafeResponse(state["status"], {}, b"")

    monkeypatch.setattr(indexnow, "fetch", fetch)
    return sent, state


def seo(actor, **values):
    update_section(actor=actor, key="seo", version=0, data=values)


def test_indexnow_is_silent_until_it_is_turned_on(engine):
    indexnow.submit(["/habari/a"])
    assert engine[0] == []


def test_indexnow_sends_whole_addresses_and_a_refusal_is_an_error(engine, make_staff, told):
    sent, state = engine
    seo(make_staff("super_admin"), indexnow=True, indexnow_key=KEY)
    indexnow.submit(["/habari/a", "/en/news/b"])
    assert sent[0]["urlList"] == ["https://www.example.com/habari/a", "https://www.example.com/en/news/b"]
    assert sent[0]["keyLocation"] == f"https://www.example.com/{KEY}.txt"
    state["status"] = 403
    with pytest.raises(RuntimeError):
        indexnow.submit(["/habari/a"])


def test_indexnow_needs_its_key(make_staff, told):
    with pytest.raises(DomainError):
        seo(make_staff("super_admin"), indexnow=True)


def test_what_search_engines_ask_for_is_public(make_staff, told, public):
    seo(make_staff("super_admin"), google_verification="abc_123", same_as=["https://example.org/news"])
    body = public("site-config").json()
    assert body["seo"]["google_verification"] == "abc_123"
    assert body["seo"]["indexnow_key"] == ""
    assert body["apps"] == {"android": "", "ios": ""}


def test_published_pages_are_announced_to_search_engines(monkeypatch):
    sent: list[list[str]] = []
    monkeypatch.setattr("newsplatform.seo.delivery.purge", lambda tags, pages: None)
    monkeypatch.setattr(tasks.index_now, "delay", sent.append)
    tasks.announce(["latest"], ["/a"])
    tasks.announce(["site"], [])
    assert sent == [["/a"]]
