"""What readers and caches get: shape, headers, query counts, and nothing that is not public."""

import json
from datetime import timedelta
from pathlib import Path

import pytest
from django.test import Client
from django.utils import timezone
from jsonschema import Draft202012Validator

from newsplatform.content import authors, publishing, services, tasks
from newsplatform.content.models import Publication
from newsplatform.content.selectors import PAGE
from newsplatform.seo.services import moved
from newsplatform.taxonomy.models import Story
from tests import factories as f

pytestmark = pytest.mark.django_db
API = json.loads((Path(__file__).parents[3] / "docs/api/openapi-public.json").read_text())


@pytest.fixture(autouse=True)
def _public(settings, monkeypatch):
    settings.ROOT_URLCONF = "config.urls_public"
    settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "IpAllowlist" not in m]  # admin only
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: None)


@pytest.fixture
def editor(make_staff):
    return make_staff("editor_in_chief")


@pytest.fixture
def cat(db):
    return f.category("habari")


def get(path: str, **headers):
    return Client().get(f"/api/v1/content/{path}", headers=headers)


def published(editor, cat, headline="Kichwa", minutes_ago=0, **kw):
    row = f.go(editor, f.post(editor, cat, headline, **kw), "publish")
    if minutes_ago:
        at = timezone.now() - timedelta(minutes=minutes_ago)
        row.published_at = at
        row.save()
        publishing.publish(row)
    return row


def matches_contract(path_template: str, body) -> None:
    """The response is what the generated clients were told to expect."""
    operation = API["paths"][f"/api/v1/content/{path_template}"]["get"]
    schema = operation["responses"]["200"]["content"]["application/json"]["schema"]
    validator = Draft202012Validator({**schema, "components": API["components"]})
    errors = [f"{list(e.absolute_path)}: {e.message[:200]}" for e in validator.iter_errors(body)]
    assert errors == []


# ---- shape -----------------------------------------------------------------------
def full(editor, cat):
    hero, clip = f.asset(), f.asset("video", outputs={"hls": "h", "poster": "p"}, duration_ms=1000)
    story = Story.objects.create(slug="uchaguzi", title_sw="Uchaguzi", title_en="Election")
    tag = f.tag("siasa")
    inline = f.asset()
    texts = {
        loc: {
            "headline": f"Kichwa {loc}",
            "standfirst": "Utangulizi",
            "body": f.body(
                "Aya.", {"type": "image", "id": "block-2", "asset": str(inline.pk), "alt": "Picha"}
            ),
        }
        for loc in ("sw", "en")
    }
    return published(editor, cat, hero=hero.pk, video=clip.pk, story=story.pk, tags=[tag.pk], texts=texts)


def test_every_endpoint_matches_its_documented_shape(editor, cat):
    child = f.category("siasa", cat)
    full(editor, child)
    live = published(editor, cat, "Mubashara", type="live_blog")
    published(editor, cat, "Haraka", breaking_until=timezone.now() + timedelta(hours=1))
    published(editor, cat, "YouTube", type="youtube", youtube_id="aqz-KE-bpKQ")
    author = editor.author.slug
    for locale in ("sw", "en"):
        suffix = "" if locale == "sw" else "-en"
        pages = {
            "home": "home",
            "latest": "latest",
            "types/{kind}": "types/live_blog",
            "categories/{slug}": f"categories/habari{suffix}",
            "tags/{slug}": "tags/siasa",
            "stories/{slug}": "stories/uchaguzi",
            "authors/{slug}": f"authors/{author}",
            "articles/{slug}": f"articles/kichwa-{locale}",
            "articles/{slug}/related": f"articles/kichwa-{locale}/related",
            "navigation": "navigation",
            "search": "search",
        }
        for template, path in pages.items():
            joiner = "&" if "?" in path else "?"
            res = get(f"{path}{joiner}locale={locale}")
            assert res.status_code == 200, (path, res.content)
            matches_contract(template, res.json())
    home = get("home").json()
    assert [c["headline"] for c in home["live"]] == ["Mubashara"]
    assert [c["headline"] for c in home["breaking"]] == ["Haraka"]
    assert home["sections"][0]["category"]["slug"] == "habari"
    assert live.pk


def test_site_config_names_the_logo_and_the_media_host(settings, editor):
    from newsplatform.site_config.models import SettingsSection

    logo = f.asset(outputs={"variants": {"webp": {"320": "k"}}})
    SettingsSection.objects.create(key="identity", data={"brand_name": "Jina", "logo_light": str(logo.pk)})
    settings.STORAGE_ENDPOINT_URL = "http://127.0.0.1:1"
    body = Client().get("/api/v1/site-config").json()
    assert body["identity"]["logo_light"]["variants"] == {"webp": {"320": "k"}}
    assert body["identity"]["logo_dark"] is None
    assert body["media_base_url"] == ""


def test_article_carries_everything_needed_to_render_it(editor, cat):
    full(editor, f.category("siasa", cat))
    body = get("articles/kichwa-sw").json()
    used = body["body"]["blocks"][1]["asset"]
    assert body["assets"][used]["kind"] == "image"
    assert [b["slug"] for b in body["breadcrumbs"]] == ["habari"]
    assert body["engagement"]["comments"] == "open"
    assert body["translations"] == [{"locale": "en", "path": "/en/siasa-en/kichwa-en"}]
    assert body["authors"][0]["path"] == f"/author/{editor.author.slug}"


def test_related_links_point_only_at_public_pages(editor, cat):
    target, hidden = published(editor, cat, "Lengo"), f.post(editor, cat, "Rasimu")
    blocks = [
        {"type": "related_link", "id": f"block-{i}x", "title": "Soma", "post": str(p.pk)}
        for i, p in enumerate((target, hidden))
    ]
    texts = {"sw": {"headline": "Chanzo", "body": f.body("Aya.", *blocks)}}
    published(editor, cat, "Chanzo", texts=texts)
    assert get("articles/chanzo").json()["links"] == {
        str(target.pk): {"path": "/habari/lengo", "headline": "Lengo"}
    }


# ---- privacy ---------------------------------------------------------------------
def test_unpublished_work_is_nowhere(editor, cat):
    draft = f.post(editor, cat, "Siri kubwa")
    gone = f.go(editor, published(editor, cat, "Imeondolewa"), "unpublish")
    for path in ("home", "latest", "categories/habari", f"articles/{draft.texts.get().slug or 'siri-kubwa'}"):
        assert b"Siri kubwa" not in get(path).content
        assert b"Imeondolewa" not in get(path).content
    assert get("articles/imeondolewa").status_code == 404
    assert gone.status == "unpublished"


def test_no_private_field_ever_reaches_a_reader(editor, cat):
    row = full(editor, cat)
    services.add_note(actor=editor, post_id=row.pk, text="siri-ya-mhariri")
    text = get("articles/kichwa-sw").content.decode()
    for secret in (editor.email, "siri-ya-mhariri", "focus_keyword", "original_key", "originals/", "locked"):
        assert secret not in text


def test_hidden_branches_are_closed(editor, cat):
    hidden = f.category("ndani", cat, visibility="hidden")
    child = f.category("ndani-zaidi", hidden)
    for slug in ("ndani", "ndani-zaidi"):
        assert get(f"categories/{slug}").status_code == 404
    assert [c["slug"] for c in get("navigation").json()] == ["habari"]
    assert get("navigation").json()[0]["children"] == []
    assert child.pk


# ---- pages -----------------------------------------------------------------------
def test_pages_join_without_gaps_or_repeats(editor, cat):
    at = timezone.now()
    rows = [published(editor, cat, f"Habari {i}") for i in range(7)]
    # Three share one instant: the id breaks the tie.
    for row in rows[:3]:
        row.published_at = at
        row.save()
        publishing.publish(row)
    seen, cursor = [], ""
    while True:
        body = get(f"latest?limit=2&cursor={cursor}").json()
        seen += [c["id"] for c in body["results"]]
        cursor = body["next_cursor"]
        if cursor is None:
            break
        published(editor, cat, f"Mpya {len(seen)}")  # something new arrives while a reader scrolls
    assert len(seen) == len(set(seen)) == 7


@pytest.mark.parametrize("cursor", ["x", "%00", "AAAA", "MjAyNi0wMS0wMXxub3BlCg", "a" * 5000])
def test_bad_cursors_are_refused(cursor):
    res = get(f"latest?cursor={cursor}")
    assert (res.status_code, res.json()["code"]) == (400, "invalid_cursor")


@pytest.mark.parametrize("query", ["limit=0", "limit=51", "limit=x", "limit=-1", "locale=fr", "locale="])
def test_bad_arguments_are_refused_and_not_cached(query):
    res = get(f"latest?{query}")
    assert res.status_code == 400
    assert res["Cache-Control"] == "no-store"


def test_only_reading_is_possible(cat):
    for method in ("post", "put", "patch", "delete"):
        assert getattr(Client(), method)("/api/v1/content/latest").status_code == 405


# ---- caches ----------------------------------------------------------------------
PATHS = [
    "home",
    "latest",
    "types/video",
    "categories/habari",
    "tags/siasa",
    "stories/uchaguzi",
    "articles/kichwa-sw",
    "articles/kichwa-sw/related",
    "navigation",
    "search",
]


@pytest.mark.parametrize("path", PATHS)
def test_every_response_is_cacheable_by_everyone(editor, cat, path):
    full(editor, cat)
    res = get(path)
    for part in ("public", "s-maxage=", "stale-while-revalidate=", "stale-if-error="):
        assert part in res["Cache-Control"], path
    assert "Set-Cookie" not in res
    assert "Cookie" not in res.headers.get("Vary", "")
    assert res["Surrogate-Key"]
    again = get(path, **{"If-None-Match": res["ETag"]})
    assert (again.status_code, again.content) == (304, b"")
    assert again["Cache-Control"] == res["Cache-Control"]


def test_etag_changes_when_a_translation_appears(editor, cat):
    row = published(editor, cat, "Kichwa")
    before = get("articles/kichwa")["ETag"]
    row.refresh_from_db()
    texts = {"en": {"headline": "Title", "body": f.body()}}
    services.save(actor=editor, post_id=row.pk, version=row.version, data={"texts": texts})
    f.go(editor, row, "republish")
    assert get("articles/kichwa")["ETag"] != before


def test_surrogate_keys_name_what_was_shown(editor, cat):
    row = full(editor, cat)
    keys = get("articles/kichwa-sw")["Surrogate-Key"].split()
    assert {f"post-{row.pk}", f"category-{cat.pk}", f"author-{editor.pk}"} <= set(keys)
    assert f"post-{row.pk}" in get("categories/habari")["Surrogate-Key"].split()


def test_missing_pages_are_cached_briefly():
    assert get("articles/hakuna")["Cache-Control"] == "public, max-age=0, s-maxage=30"


# ---- cost ------------------------------------------------------------------------
QUERIES = {
    "home": 6,  # tree 2, lists 2, breaking, live
    "latest": 1,
    "types/video": 1,
    "categories/habari": 3,
    "tags/tag-0": 2,
    "stories/story-0": 2,
    "articles/kichwa-0": 1,
    "articles/kichwa-0/related": 4,
    "navigation": 2,
    "search": 0,
}


@pytest.mark.parametrize(("path", "limit"), QUERIES.items())
def test_query_counts_do_not_grow_with_content(editor, cat, path, limit, django_assert_max_num_queries):
    def fill(start, count):
        for i in range(start, start + count):
            extra = f.category(f"kundi-{i}")
            story, _ = Story.objects.get_or_create(slug=f"story-{i}", title_sw="H", title_en="S")
            tag = f.tag(f"tag-{i}")
            published(editor, extra if i % 2 else cat, f"Kichwa {i}", story=story.pk, tags=[tag.pk])

    fill(0, 2)
    with django_assert_max_num_queries(limit):
        assert get(path).status_code == 200
    fill(2, 6)
    with django_assert_max_num_queries(limit):
        assert get(path).status_code == 200


def test_author_page_costs_two_queries(editor, cat, django_assert_max_num_queries):
    for i in range(4):
        published(editor, cat, f"Kichwa {i}")
    slug = editor.author.slug
    with django_assert_max_num_queries(2):
        assert len(get(f"authors/{slug}").json()["results"]) == 4


# ---- related, home -----------------------------------------------------------------
def test_related_prefers_the_story_then_tags_then_the_section(editor, cat):
    story, tag = Story.objects.create(slug="s", title_sw="S", title_en="S"), f.tag("t")
    published(editor, cat, "Sehemu", minutes_ago=1)
    published(editor, f.category("nyingine"), "Lebo", minutes_ago=5, tags=[tag.pk])
    published(editor, f.category("tatu"), "Hadithi", minutes_ago=9, story=story.pk)
    published(editor, cat, "Mimi", story=story.pk, tags=[tag.pk])
    assert [c["headline"] for c in get("articles/mimi/related").json()["results"]] == [
        "Hadithi",
        "Lebo",
        "Sehemu",
    ]


def test_home_leads_with_pictures_and_never_repeats_them(editor, cat):
    hero = f.asset()
    for i in range(7):
        published(editor, cat, f"Picha {i}", hero=hero.pk)
    published(editor, cat, "Nyeti", hero=hero.pk, is_sensitive=True)
    published(editor, cat, "Bila picha")
    body = get("home").json()
    lead, latest = ([c["headline"] for c in body[k]] for k in ("lead", "latest"))
    assert len(lead) == 5
    assert not {"Nyeti", "Bila picha"} & set(lead)
    assert not set(lead) & set(latest)


def test_breaking_and_live_end(editor, cat):
    row = published(editor, cat, "Haraka", breaking_until=timezone.now() - timedelta(minutes=1))
    blog = published(editor, cat, "Mubashara", type="live_blog")
    assert get("home").json()["breaking"] == []
    blog.refresh_from_db()
    services.save(actor=editor, post_id=blog.pk, version=blog.version, data={"live_ended_at": timezone.now()})
    assert len(get("home").json()["live"]) == 1  # not until it is republished
    f.go(editor, blog, "republish")
    assert get("home").json()["live"] == []
    assert row.pk


def test_old_addresses_resolve(cat):
    moved("/habari/zamani", "/habari/mpya")
    assert get("resolve?path=/habari/zamani").json() == {"path": "/habari/mpya"}
    assert get("resolve?path=/habari/hakuna").status_code == 404
    assert get("resolve?path=//evil.example").status_code == 404
    assert get("resolve?path=zamani").status_code == 400


def test_a_changed_author_is_changed_everywhere(editor, cat, django_capture_on_commit_callbacks):
    published(editor, cat, "Kichwa")
    with django_capture_on_commit_callbacks(execute=True):
        authors.update(actor=editor, user_id=editor.pk, data={"title_sw": "Mhariri Mkuu"})
    assert get("articles/kichwa").json()["authors"][0]["title"] == "Mhariri Mkuu"
    assert get("latest").json()["results"][0]["authors"][0]["title"] == "Mhariri Mkuu"


def test_page_size_is_the_documented_default(editor, cat):
    assert PAGE == 20
    assert Publication.objects.count() == 0


def test_the_public_surface_has_no_editing_routes():
    for path in ("posts", "media", "categories", "redirects"):
        assert Client().get(f"/api/v1/{path}").status_code == 404
