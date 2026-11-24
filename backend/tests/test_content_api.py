"""The admin endpoints: what a person may reach, and what the browser is told."""

import json
from datetime import timedelta
from urllib.parse import urlencode

import pytest
from django.utils import timezone

from newsplatform.audit.models import AuditEntry
from newsplatform.content import diffing, services, tasks
from newsplatform.content.models import AuthorProfile, Post
from newsplatform.media import services as media
from newsplatform.media import tasks as media_tasks
from newsplatform.media import youtube
from newsplatform.rbac.models import RoleAssignment
from newsplatform.seo.models import Redirect
from newsplatform.seo.services import resolve
from newsplatform.site_config.models import SettingsSection
from newsplatform.taxonomy.models import Category, Tag
from tests import factories as f

pytestmark = pytest.mark.django_db


@pytest.fixture(autouse=True)
def _quiet(monkeypatch):
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: None)


@pytest.fixture
def cat(db):
    return f.category("habari")


@pytest.fixture
def desk(admin_api):
    return admin_api("editor_in_chief")


# ---- writing ----------------------------------------------------------------------
def test_from_first_word_to_published_page(desk, cat):
    _, api = desk
    res = api.post(
        "posts", {"type": "article", "category": str(cat.pk), "locale": "sw", "headline": "Kichwa"}
    )
    assert res.status_code == 201, res.content
    post = res.json()
    assert post["problems"] == ["body"]
    assert {t["key"] for t in post["transitions"]} >= {"submit", "publish"}
    data = {"texts": {"sw": {"body": f.body("Maneno."), "standfirst": "Utangulizi"}}}
    saved = api.put(f"posts/{post['id']}", {"version": post["version"], "data": data}).json()
    assert (saved["version"], saved["problems"]) == (2, [])
    preview = api.get(f"posts/{post['id']}/preview?locale=sw").json()["article"]
    assert (preview["headline"], preview["path"]) == ("Kichwa", "/habari/kichwa")
    live = api.post(f"posts/{post['id']}/transition", {"key": "publish", "version": 2}).json()
    assert (live["status"], live["paths"]) == ("published", {"sw": "/habari/kichwa"})
    assert live["unpublished_changes"] is False
    data = {"texts": {"sw": {"headline": "Kichwa kipya"}}}
    again = api.put(f"posts/{post['id']}", {"version": live["version"], "data": data}).json()
    assert again["unpublished_changes"] is True


def test_preview_changes_nothing(desk, cat, django_assert_num_queries):
    user, api = desk
    post = f.post(user, cat)
    before = (Post.objects.get().updated_at, AuthorProfile.objects.count())
    assert api.get(f"posts/{post.pk}/preview?locale=sw").status_code == 200
    assert (Post.objects.get().updated_at, AuthorProfile.objects.count()) == before
    assert api.get(f"posts/{post.pk}/preview?locale=en").status_code == 404


@pytest.mark.parametrize(
    ("data", "field"),
    [
        ({"youtube_id": "short"}, "youtube_id"),
        ({"youtube_id": "aqz-KE-bpKQ\n"}, "youtube_id"),
        ({"source_url": "javascript:alert(1)"}, "source_url"),
        ({"type": "nope"}, "type"),
        ({"engagement": {"comments": "loud"}}, "engagement"),
        ({"tags": ["x"]}, "tags"),
        ({"texts": {"fr": {}, "sw": {"headline": "x" * 201}}}, "texts"),
    ],
)
def test_bad_input_is_a_400_not_a_crash(desk, cat, data, field):
    user, api = desk
    post = f.post(user, cat)
    res = api.put(f"posts/{post.pk}", {"version": post.version, "data": data})
    if data.get("youtube_id", "").endswith("\n"):  # trimmed by the field, then valid
        assert res.json()["data"]["youtube_id"] == "aqz-KE-bpKQ"
        return
    assert res.status_code == 400, res.content
    assert field in json.dumps(res.json()["errors"])


def test_invalid_blocks_name_the_place(desk, cat):
    user, api = desk
    post = f.post(user, cat)
    body = {"version": 1, "blocks": [{"type": "embed", "id": "block-1", "provider": "x", "url": "http://x"}]}
    res = api.put(f"posts/{post.pk}", {"version": post.version, "data": {"texts": {"sw": {"body": body}}}})
    assert (res.status_code, res.json()["code"]) == (400, "invalid_content")
    assert res.json()["errors"][0]["field"].startswith("blocks.0")


def test_stale_and_locked_saves_say_so(desk, new_api, make_staff, cat):
    user, api = desk
    post = f.post(user, cat)
    api.put(f"posts/{post.pk}", {"version": post.version, "data": {"is_evergreen": True}})
    stale = api.put(f"posts/{post.pk}", {"version": post.version, "data": {}})
    assert (stale.status_code, stale.json()["code"]) == (409, "stale_version")
    other = new_api(ip="203.0.113.9").sign_in(make_staff("editor_in_chief"))
    locked = other.put(f"posts/{post.pk}", {"version": post.version + 1, "data": {}})
    assert (locked.json()["code"], locked.json()["holder"]) == ("locked", user.display_name)
    assert other.get(f"posts/{post.pk}").json()["editing"]["display_name"] == user.display_name
    assert other.post(f"posts/{post.pk}/lock").status_code == 409
    assert other.post(f"posts/{post.pk}/lock", {"force": True}).status_code == 200
    assert other.delete(f"posts/{post.pk}/lock").status_code == 204


def test_people_without_content_rights_are_refused(admin_api, cat, desk):
    post = f.post(desk[0], cat)
    _, api = admin_api("moderator")
    for path in ("posts", f"posts/{post.pk}", "media", "categories", "authors", "redirects"):
        assert api.get(path).status_code == 403, path


def test_a_journalist_sees_their_own_posts_only(desk, admin_api, cat):
    editor, editor_api = desk
    journalist, api = admin_api("journalist")
    theirs = f.post(editor, cat, "Ya mhariri")
    mine = f.post(journalist, cat, "Yangu")
    assert [r["id"] for r in api.get("posts").json()["results"]] == [str(mine.pk)]
    for path in ("", "/preview?locale=sw", "/revisions", "/notes", "/revisions/1/diff"):
        assert api.get(f"posts/{theirs.pk}{path}").status_code == 404, path
    assert len(editor_api.get("posts").json()["results"]) == 2


def test_a_section_editor_sees_their_branch(new_api, make_staff, roles, desk, cat):
    child, other = f.category("siasa", cat), f.category("michezo")
    rows = {c.pk: f.post(desk[0], c, f"Ya {c.pk}") for c in (cat, child, other)}
    person = make_staff("contributor")
    RoleAssignment.objects.create(
        user=person, role=roles["section_editor"], scope_type="category", scope_id=str(cat.pk)
    )
    api = new_api(ip="203.0.113.8").sign_in(person)
    seen = {r["id"] for r in api.get("posts").json()["results"]}
    assert seen == {str(rows[cat.pk].pk), str(rows[child.pk].pk)}
    by_id = {c["id"]: c for c in api.get("categories").json()}
    assert by_id[str(child.pk)]["can_manage"] is False
    assert (
        api.put(f"categories/{other.pk}", {"version": 1, "texts": {"sw": {"name": "X"}}}).status_code == 403
    )


def test_list_filters(desk, cat):
    user, api = desk
    child = f.category("siasa", cat)
    a = f.go(user, f.post(user, cat, "Mvua kubwa"), "publish")
    b = f.post(user, child, "Jua kali", type="opinion")

    def ids(query):
        return {r["id"] for r in api.get(f"posts?{query}").json()["results"]}

    assert ids("status=published") == {str(a.pk)}
    assert ids("status=published&status=draft") == ids("") == {str(a.pk), str(b.pk)}
    assert ids("type=opinion") == {str(b.pk)}
    assert ids(f"category={cat.pk}") == {str(a.pk), str(b.pk)}
    assert ids(f"category={child.pk}") == {str(b.pk)}
    assert ids("q=MVUA") == {str(a.pk)}
    assert ids(f"author={user.pk}") == {str(a.pk), str(b.pk)}
    soon = (timezone.now() + timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    ago = (timezone.now() - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    assert ids(f"from={ago}&to={soon}") == {str(a.pk)}
    assert api.get("posts?category=x").status_code == 400
    assert api.get("posts?from=x").status_code == 400


def test_list_queries_do_not_grow(desk, cat, django_assert_max_num_queries):
    user, api = desk
    for i in range(3):
        f.post(user, cat, f"Kichwa {i}")
    api.get("posts")
    with django_assert_max_num_queries(16) as few:
        api.get("posts")
    for i in range(12):
        f.post(user, cat, f"Zaidi {i}")
    with django_assert_max_num_queries(len(few)):
        assert len(api.get("posts").json()["results"]) == 15


# ---- revisions -----------------------------------------------------------------------
def test_the_calendar_is_complete_and_in_order(desk, admin_api, cat, django_assert_max_num_queries):
    user, api = desk
    now = timezone.now()
    ids = []
    for hours in (30, -2, -3):
        post = f.post(user, cat)
        key = "schedule" if hours > 0 else "publish"
        when = {"scheduled_at": now + timedelta(hours=hours)} if hours > 0 else {}
        services.transition(actor=user, post_id=post.pk, key=key, version=post.version, **when)
        if hours < 0:
            Post.objects.filter(pk=post.pk).update(published_at=now + timedelta(hours=hours))
        ids.append(str(post.pk))
    f.post(user, cat)  # a draft has no day
    span = {"from": (now - timedelta(days=1)).isoformat(), "to": (now + timedelta(days=6)).isoformat()}
    with django_assert_max_num_queries(12):
        got = api.get(f"posts/calendar?{urlencode(span)}").json()
    assert [r["id"] for r in got["results"]] == [ids[2], ids[1], ids[0]]
    assert [r["status"] for r in got["results"]] == ["published", "published", "scheduled"]
    assert got["truncated"] is False
    _, other = admin_api("journalist")
    assert other.get(f"posts/calendar?{urlencode(span)}").json()["results"] == []
    far = {"from": now.isoformat(), "to": (now + timedelta(days=90)).isoformat()}
    assert api.get(f"posts/calendar?{urlencode(far)}").status_code == 400
    assert api.get("posts/calendar").status_code == 400


def test_diff_shows_words_and_blocks(desk, cat):
    user, api = desk
    post = f.post(user, cat, "Mvua kubwa yanyesha")
    body = f.body(
        "Aya ya kwanza.",
        {"type": "paragraph", "id": "block-2", "content": [{"type": "text", "text": "Mpya"}]},
    )
    data = {"is_sensitive": True, "texts": {"sw": {"headline": "Mvua ndogo yanyesha", "body": body}}}
    api.put(f"posts/{post.pk}", {"version": post.version, "data": data})
    number = api.get(f"posts/{post.pk}/revisions").json()["results"][0]["number"]
    diff = api.get(f"posts/{post.pk}/revisions/{number}/diff").json()
    assert diff["fields"] == ["is_sensitive"]
    text = diff["texts"][0]
    assert text["fields"][0]["words"] == [
        {"op": "same", "text": "Mvua "},
        {"op": "del", "text": "kubwa"},
        {"op": "add", "text": "ndogo"},
        {"op": "same", "text": " yanyesha"},
    ]
    assert [(b["op"], b["id"]) for b in text["blocks"]] == [("same", "block-1"), ("added", "block-2")]
    assert api.get(f"posts/{post.pk}/revisions/99/diff").status_code == 404
    assert api.get(f"posts/{post.pk}/revisions/{number}/diff?from=99").status_code == 404
    first = api.get(f"posts/{post.pk}/revisions/1/diff").json()
    assert first["texts"][0]["fields"]


@pytest.mark.parametrize(
    ("old", "new"),
    [("", "abc"), ("abc", ""), ("a b c", "a c"), ("Ng'ombe wa mama", "Ng'ombe wa baba"), ("x " * 5000, "y")],
)
def test_word_diffs_rebuild_both_sides(old, new):
    runs = diffing.words(old, new)
    assert "".join(r["text"] for r in runs if r["op"] != "add") == old
    assert "".join(r["text"] for r in runs if r["op"] != "del") == new


def test_a_moved_block_is_not_a_rewrite():
    p = lambda i: {"type": "paragraph", "id": i, "content": [{"type": "text", "text": i}]}  # noqa: E731
    ops = diffing.body({"blocks": [p("a"), p("b"), p("c")]}, {"blocks": [p("c"), p("a"), p("b")]})
    assert sorted((o["op"], o["id"]) for o in ops) == [("moved", "c"), ("same", "a"), ("same", "b")]


def test_restore_through_the_api(desk, cat):
    user, api = desk
    post = f.post(user, cat, "Wa kwanza")
    v = api.put(
        f"posts/{post.pk}", {"version": post.version, "data": {"texts": {"sw": {"headline": "Wa pili"}}}}
    ).json()["version"]
    res = api.post(f"posts/{post.pk}/revisions/2/restore", {"version": v})
    assert res.json()["data"]["texts"]["sw"]["headline"] == "Wa kwanza"
    assert api.post(f"posts/{post.pk}/revisions/99/restore", {"version": v + 1}).status_code == 404


def test_notes_stay_in_the_newsroom(desk, cat):
    user, api = desk
    post = f.post(user, cat)
    assert api.post(f"posts/{post.pk}/notes", {"text": "Angalia chanzo"}).status_code == 201
    assert api.get(f"posts/{post.pk}/notes").json()["results"][0]["text"] == "Angalia chanzo"


# ---- live, bulk -----------------------------------------------------------------------
def test_live_updates_go_out_at_once_newest_first(desk, cat):
    user, api = desk
    post = f.go(user, f.post(user, cat, "Mubashara", type="live_blog"), "publish")
    paragraph = {"type": "paragraph", "id": "update-1-p", "content": [{"type": "text", "text": "Goli!"}]}
    block = {"id": "update-1", "title": "Dakika ya 5", "blocks": [paragraph]}
    res = api.post(f"posts/{post.pk}/live-updates", {"version": post.version, "locale": "sw", "block": block})
    assert res.status_code == 200, res.content
    page = post.publications.get().article["body"]["blocks"]
    assert (page[0]["type"], page[0]["id"], page[1]["id"]) == ("live_update", "update-1", "block-1")
    article = f.post(user, cat, "Makala")
    bad = api.post(
        f"posts/{article.pk}/live-updates", {"version": article.version, "locale": "sw", "block": block}
    )
    assert bad.json()["code"] == "not_live_blog"


def test_bulk_reports_each_post(desk, cat):
    user, api = desk
    ok, not_ready = f.post(user, cat, "Tayari"), f.post(user, cat, "Bado", youtube_id="", type="youtube")
    missing = "00000000-0000-7000-8000-000000000000"
    body = {"key": "publish", "ids": [str(ok.pk), str(not_ready.pk), missing]}
    out = api.post("posts/bulk", body).json()
    assert [r["result"] for r in out["results"]] == ["ok", "not_ready", "not_found"]
    ok.refresh_from_db()
    assert ok.status == "published"


def test_removing_many_needs_a_second_person(desk, make_staff, admin_api, cat):
    SettingsSection.objects.create(key="security", data={"four_eyes": "on"})
    user, api = desk
    posts = [f.post(user, cat, f"Kichwa {i}") for i in range(services.BULK_FOUR_EYES)]
    body = {"key": "archive", "ids": [str(p.pk) for p in posts], "note": "Zamani"}
    assert api.post("posts/bulk", {**body, "ids": body["ids"][:9]}).json()["approval_required"] is False
    for p in posts[:9]:
        f.go(user, p, "restore")
    out = api.post("posts/bulk", body).json()
    assert out == {"approval_required": True, "results": []}
    assert Post.objects.filter(status="archived").count() == 0
    _, boss = admin_api("super_admin")
    pending = boss.get("approvals").json()["results"][0]
    res = boss.post(f"approvals/{pending['id']}/approve", {"note": "Sawa"})
    assert res.status_code == 200, res.content
    assert Post.objects.filter(status="archived").count() == len(posts)


# ---- authors -----------------------------------------------------------------------
def test_people_write_their_own_page(admin_api, desk):
    journalist, api = admin_api("journalist")
    body = {"title_sw": "Mwandishi wa siasa", "links": ["https://example.org/asha"], "expertise": ["Siasa"]}
    assert api.put(f"authors/{journalist.pk}", body).json()["title_sw"] == "Mwandishi wa siasa"
    assert api.put(f"authors/{desk[0].pk}", body).status_code == 403
    assert AuditEntry.objects.filter(action="author.updated").count() == 1
    for link in ("http://x.y", "javascript:alert(1)", "https://u:p@x.y", "https://"):
        assert api.put(f"authors/{journalist.pk}", {"links": [link]}).status_code == 400, link


def test_an_avatar_is_a_finished_picture(admin_api):
    user, api = admin_api("journalist")
    bad = f.asset(status="processing")
    good = f.asset()
    assert api.put(f"authors/{user.pk}", {"avatar": str(bad.pk)}).json()["code"] == "wrong_asset_kind"
    assert api.put(f"authors/{user.pk}", {"avatar": str(good.pk)}).json()["avatar"]["id"] == str(good.pk)
    detail = api.get(f"media/{good.pk}").json()
    assert detail["elsewhere"] == ["author"]
    assert api.put(f"authors/{user.pk}", {"avatar": None}).json()["avatar"] is None


# ---- taxonomy -----------------------------------------------------------------------
def test_category_tree_through_the_api(desk):
    _, api = desk
    root = api.post("categories", {"texts": {"sw": {"name": "Michezo"}, "en": {"name": "Sport"}}}).json()
    child = api.post("categories", {"parent": root["id"], "texts": {"sw": {"name": "Soka"}}}).json()
    rows = {c["id"]: c for c in api.get("categories").json()}
    assert rows[child["id"]]["parent"] == root["id"]
    assert rows[root["id"]]["texts"]["en"]["slug"] == "sport"
    saved = api.put(
        f"categories/{child['id']}",
        {"version": 1, "color": "#AA0000", "texts": {"sw": {"name": "Soka", "slug": "soka"}}},
    )
    assert saved.json() == {"version": 2}
    assert Category.objects.get(pk=child["id"]).color == "#aa0000"
    assert api.post(f"categories/{child['id']}/move", {"parent": None, "position": 0}).status_code == 204
    assert api.post(f"categories/{child['id']}/merge", {"target": root["id"]}).status_code == 204
    assert not Category.objects.filter(pk=child["id"]).exists()
    reserved = api.post("categories", {"texts": {"sw": {"name": "Video", "slug": "video"}}})
    assert reserved.json()["code"] == "slug_reserved"


def test_tags_stories_regions(desk):
    _, api = desk
    a = api.post("tags", {"name_sw": "Uchaguzi", "name_en": "Election", "synonyms": ["Kura"]}).json()
    b = api.post("tags", {"name_sw": "Kampeni", "name_en": "Campaign"}).json()
    assert [t["id"] for t in api.get("tags?q=kura").json()["results"]] == [a["id"]]
    saved = api.put(f"tags/{b['id']}", {"name_sw": "Kampeni", "name_en": "Campaigns", "slug": "kampeni"})
    assert saved.json()["name_en"] == "Campaigns"
    assert api.post(f"tags/{b['id']}/merge", {"target": a["id"]}).status_code == 204
    assert Tag.objects.get(pk=b["id"]).merged_into_id
    assert api.put(f"tags/{b['id']}", {"name_sw": "x", "name_en": "x"}).status_code == 404
    story = api.post("stories", {"title_sw": "Uchaguzi 2027", "title_en": "Election 2027"}).json()
    edited = api.put(f"stories/{story['id']}", {**story, "is_active": False}).json()
    assert edited["is_active"] is False
    assert len(api.get("stories?q=2027").json()["results"]) == 1
    assert api.post("regions", {"name_sw": "Dodoma", "name_en": "Dodoma"}).status_code == 201
    assert api.get("regions").json()[0]["slug"] == "dodoma"


def test_redirects_by_hand(desk, cat):
    user, api = desk
    f.go(user, f.post(user, cat, "Kichwa"), "publish")
    made = api.post("redirects", {"from_path": "/zamani", "to_path": "/habari/kichwa"})
    assert made.status_code == 201, made.content
    assert resolve("/zamani") == "/habari/kichwa"
    for bad, code in [
        ({"from_path": "/a", "to_path": "https://evil.example"}, "invalid_path"),
        ({"from_path": "/a", "to_path": "//evil.example"}, "invalid_path"),
        ({"from_path": "/a", "to_path": "/\\evil.example"}, "invalid_path"),
        ({"from_path": "/habari/kichwa", "to_path": "/a"}, "path_in_use"),
        ({"from_path": "/", "to_path": "/a"}, "path_in_use"),
        ({"from_path": "/a", "to_path": "/a"}, "redirect_loop"),
    ]:
        res = api.post("redirects", bad)
        assert res.json().get("code") == code, res.content
    # Pointing at an address that has itself moved keeps both.
    assert api.post("redirects", {"from_path": "/kale", "to_path": "/zamani"}).status_code == 201
    assert resolve("/kale") == resolve("/zamani") == "/habari/kichwa"
    row = Redirect.objects.get(from_path="/zamani")
    assert api.delete(f"redirects/{row.pk}").status_code == 204
    assert AuditEntry.objects.filter(action="redirect.deleted").count() == 1


# ---- media, settings -------------------------------------------------------------------
def test_library_search_and_detail(admin_api, cat):
    user, api = admin_api("journalist")
    image = f.asset(outputs={"variants": {"webp": {"320": "k/320.webp", "1280": "k/1280.webp"}}})
    clip = f.asset("video", outputs={"hls": "v/m.m3u8", "poster": "v/p.jpg"}, alt_sw="Goli")
    waiting = f.asset(status="scanning", outputs={"variants": {"webp": {"320": "k"}}})
    rows = {r["id"]: r for r in api.get("media").json()["results"]}
    assert rows[str(image.pk)]["thumb_url"].endswith("k/320.webp")
    assert rows[str(clip.pk)]["hls_url"].endswith("v/m.m3u8")
    assert rows[str(waiting.pk)]["thumb_url"] == ""  # never shown before it is scanned
    assert [r["id"] for r in api.get("media?kind=video&q=goli").json()["results"]] == [str(clip.pk)]
    post = f.post(user, cat, hero=image.pk)
    assert api.get(f"media/{image.pk}").json()["posts"] == [
        {"id": str(post.pk), "headline": "Kichwa cha habari"}
    ]
    res = api.request("PATCH", f"media/{image.pk}", {"credit": "X"})
    assert res.status_code == 403  # not theirs


def test_youtube_import_mirrors_the_thumbnail_once(admin_api, monkeypatch):
    _, api = admin_api("journalist")
    stored = {}
    monkeypatch.setattr(youtube, "metadata", lambda link: youtube.Metadata("Kichwa", "Kituo", 200, 113))
    monkeypatch.setattr(youtube, "thumbnail", lambda link: b"\xff\xd8\xffdata")
    monkeypatch.setattr(
        media, "storage", lambda: type("S", (), {"put": lambda s, k, d: stored.update({k: d})})()
    )
    monkeypatch.setattr(media_tasks.process, "delay", lambda pk: None)
    first = api.post("media/youtube", {"url": "https://youtu.be/aqz-KE-bpKQ?t=90"}).json()
    again = api.post("media/youtube", {"url": "https://www.youtube.com/watch?v=aqz-KE-bpKQ"}).json()
    assert (first["video_id"], first["start"], first["vertical"]) == ("aqz-KE-bpKQ", 90, False)
    assert first["thumbnail"]["credit"] == "YouTube / Kituo"
    assert first["thumbnail"]["id"] == again["thumbnail"]["id"]
    assert len(stored) == 1
    assert api.post("media/youtube", {"url": "https://vimeo.com/1"}).json()["code"] == "not_youtube"
