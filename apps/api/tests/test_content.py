from datetime import timedelta

import pytest
from django.utils import timezone

from newsplatform.audit.models import AuditEntry
from newsplatform.common.errors import Conflict, DomainError, Forbidden, NotFound
from newsplatform.content import publishing, services, tasks
from newsplatform.content.models import Feed, Listing, Post, Publication, Revision, Status
from newsplatform.content.workflow import TRANSITIONS
from newsplatform.rbac.models import RoleAssignment
from newsplatform.seo.services import resolve as redirect_for
from newsplatform.site_config.models import SettingsSection
from newsplatform.taxonomy import services as taxonomy
from tests import factories as f

pytestmark = pytest.mark.django_db


@pytest.fixture(autouse=True)
def _quiet(monkeypatch):
    """Delivery has its own tests."""
    sent = []
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: sent.append((tags, pages)))
    return sent


@pytest.fixture
def cat(db):
    return f.category("habari")


@pytest.fixture
def editor(make_staff):
    return make_staff("editor_in_chief")


@pytest.fixture
def journalist(make_staff):
    return make_staff("journalist")


# ---- workflow ------------------------------------------------------------------------------------------
# Who may do what, written by hand: the product's promise, not a copy of the code.
MATRIX = {
    "submit": {"author", "section_editor", "editor_in_chief"},
    "withdraw": {"author", "section_editor", "editor_in_chief"},
    "start_review": {"section_editor", "editor_in_chief"},
    "request_changes": {"section_editor", "editor_in_chief"},
    "approve": {"section_editor", "editor_in_chief"},
    "schedule": {"section_editor", "editor_in_chief"},
    "unschedule": {"section_editor", "editor_in_chief"},
    "publish": {"section_editor", "editor_in_chief"},
    "republish": {"section_editor", "editor_in_chief"},
    "unpublish": {"section_editor", "editor_in_chief"},
    "archive": {"editor_in_chief"},
    "restore": {"editor_in_chief"},
}
PEOPLE = ["author", "journalist", "contributor", "section_editor", "editor_in_chief", "moderator", "analyst"]


def test_the_matrix_covers_every_transition():
    assert MATRIX.keys() == TRANSITIONS.keys()


@pytest.mark.parametrize("key", TRANSITIONS)
@pytest.mark.parametrize("who", PEOPLE)
def test_permission_matrix(make_staff, cat, key, who):
    author = make_staff("journalist")
    person = author if who == "author" else make_staff(who)
    post = f.post(author, cat)
    step = TRANSITIONS[key]
    allowed_from = set()
    for source in step.sources:
        post.status = source
        if services.may(person, post, step):
            allowed_from.add(source)
    # Publishing from a draft skips review, so it needs publish_direct as well.
    if who == "section_editor" and key in ("publish", "schedule"):
        assert allowed_from == step.sources - {Status.DRAFT}
    else:
        assert allowed_from == (step.sources if who in MATRIX[key] else set())


@pytest.mark.parametrize("key", TRANSITIONS)
def test_transitions_are_refused_from_any_other_status(editor, cat, key):
    post = f.post(editor, cat)
    for status in set(Status.values) - TRANSITIONS[key].sources:
        Post.objects.filter(pk=post.pk).update(
            status=status, scheduled_at=timezone.now(), published_at=timezone.now()
        )
        with pytest.raises(Conflict) as e:
            services.transition(actor=editor, post_id=post.pk, key=key, version=post.version, note="sababu")
        assert e.value.code == "invalid_transition"
        assert e.value.status == 409


def test_a_section_editor_works_only_in_their_section_and_its_branch(make_staff, roles, cat):
    sport = f.category("michezo")
    football = f.category("soka", sport)
    person = f.scoped(make_staff("journalist"), roles["section_editor"], sport)
    RoleAssignment.objects.filter(user=person, scope_type="").delete()
    author = make_staff("journalist")
    for where, ok in ((sport, True), (football, True), (cat, False)):
        post = f.post(author, where)
        assert services.can_view(person, post) is ok
        assert services.can_edit(person, post) is ok
        post = f.go(author, post, "submit")
        assert services.may(person, post, TRANSITIONS["approve"]) is ok


def test_a_secondary_category_gives_no_rights(make_staff, roles, cat):
    sport = f.category("michezo")
    person = f.scoped(make_staff("journalist"), roles["section_editor"], sport)
    RoleAssignment.objects.filter(user=person, scope_type="").delete()
    post = f.post(make_staff("editor_in_chief"), cat, secondary_categories=[str(sport.pk)])
    assert not services.can_edit(person, post)


def test_moving_a_post_needs_rights_at_the_destination(make_staff, roles, cat):
    sport = f.category("michezo")
    person = f.scoped(make_staff("journalist"), roles["section_editor"], cat)
    RoleAssignment.objects.filter(user=person, scope_type="").delete()
    post = f.post(person, cat)
    with pytest.raises(Forbidden):
        services.save(actor=person, post_id=post.pk, version=post.version, data={"category": str(sport.pk)})


def test_someone_elses_draft_looks_like_a_missing_one(make_staff, journalist, cat):
    post = f.post(make_staff("journalist"), cat)
    with pytest.raises(NotFound):
        services.get_for(journalist, post.pk)


def test_an_author_cannot_change_what_a_reviewer_is_reading(journalist, cat):
    post = f.go(journalist, f.post(journalist, cat), "submit")
    with pytest.raises(Forbidden):
        services.save(actor=journalist, post_id=post.pk, version=post.version, data={"is_evergreen": True})


def test_only_an_editor_adds_authors(journalist, editor, make_staff, cat):
    friend = make_staff("journalist")
    post = f.post(journalist, cat)
    both = [str(journalist.pk), str(friend.pk)]
    with pytest.raises(Forbidden):
        services.save(actor=journalist, post_id=post.pk, version=post.version, data={"authors": both})
    post = services.save(actor=editor, post_id=post.pk, version=post.version, data={"authors": both})
    assert services.can_edit(friend, post)


def test_notes_are_required_where_someone_needs_a_reason(journalist, editor, cat):
    post = f.go(journalist, f.post(journalist, cat), "submit")
    with pytest.raises(DomainError) as e:
        services.transition(actor=editor, post_id=post.pk, key="request_changes", version=post.version)
    assert e.value.code == "note_required"
    post = f.go(editor, post, "request_changes")
    assert post.notes.filter(transition="request_changes").count() == 1


def test_available_lists_exactly_what_would_succeed(journalist, editor, cat):
    post = f.post(journalist, cat)
    assert services.available(journalist, post) == ["submit"]
    assert set(services.available(editor, post)) == {"submit", "schedule", "publish", "archive"}


# ---- saving ----------------------------------------------------------------------------------------------
def test_two_editors_cannot_overwrite_each_other(editor, cat):
    post = f.post(editor, cat)
    services.save(actor=editor, post_id=post.pk, version=post.version, data={"is_evergreen": True})
    with pytest.raises(Conflict) as e:
        services.save(actor=editor, post_id=post.pk, version=post.version, data={"is_sensitive": True})
    assert e.value.code == "stale_version"


def test_soft_lock_warns_expires_and_can_be_taken(editor, make_staff, cat):
    other = make_staff("editor_in_chief")
    post = f.post(editor, cat)
    services.take_lock(actor=editor, post_id=post.pk)
    with pytest.raises(Conflict) as e:
        services.take_lock(actor=other, post_id=post.pk)
    assert e.value.extra["holder"] == editor.display_name
    with pytest.raises(Conflict):
        services.save(actor=other, post_id=post.pk, version=post.version, data={"is_sensitive": True})
    services.take_lock(actor=other, post_id=post.pk, force=True)
    assert AuditEntry.objects.filter(action="post.lock_taken").count() == 1
    Post.objects.filter(pk=post.pk).update(locked_at=timezone.now() - services.LOCK_TTL)
    services.take_lock(actor=editor, post_id=post.pk)
    services.release_lock(actor=other, post_id=post.pk)
    assert services.lock_holder(Post.objects.get(pk=post.pk)) == editor


def test_autosave_replaces_itself_and_is_not_audited(editor, cat):
    post = f.post(editor, cat)
    audits, revisions = AuditEntry.objects.count(), Revision.objects.count()
    for i in range(6):
        post = services.save(
            actor=editor,
            post_id=post.pk,
            version=post.version,
            data={"texts": {"sw": {"headline": f"Toleo {i}"}}},
            autosave=True,
        )
    assert Revision.objects.count() == revisions + 1
    assert AuditEntry.objects.count() == audits
    assert post.revisions.first().snapshot["texts"]["sw"]["headline"] == "Toleo 5"


def test_saving_nothing_leaves_no_trace(editor, cat):
    post = f.post(editor, cat)
    before = Revision.objects.count(), AuditEntry.objects.count()
    services.save(actor=editor, post_id=post.pk, version=post.version, data={})
    assert (Revision.objects.count(), AuditEntry.objects.count()) == before


def test_restore_returns_the_words_but_not_the_rights(editor, journalist, make_staff, cat):
    friend = make_staff("journalist")
    both = [str(journalist.pk), str(friend.pk)]
    post = f.post(journalist, cat)
    post = services.save(actor=editor, post_id=post.pk, version=post.version, data={"authors": both})
    old = post.revisions.first().number
    services.release_lock(actor=editor, post_id=post.pk)
    post = services.save(
        actor=editor,
        post_id=post.pk,
        version=post.version,
        data={"authors": [str(journalist.pk)], "texts": {"sw": {"headline": "Mpya"}}},
    )
    services.release_lock(actor=editor, post_id=post.pk)
    post = services.restore_revision(actor=journalist, post_id=post.pk, number=old, version=post.version)
    assert post.texts.get().headline == "Kichwa cha habari"
    assert [b.user_id for b in post.bylines.all()] == [journalist.pk]
    assert post.revisions.first().kind == "restore"


def test_restore_drops_a_translation_added_later(editor, cat):
    post = f.post(editor, cat)
    old = post.revisions.first().number
    post = services.save(
        actor=editor,
        post_id=post.pk,
        version=post.version,
        data={"texts": {"en": {"headline": "Headline", "body": f.body("Text")}}},
    )
    post = services.restore_revision(actor=editor, post_id=post.pk, number=old, version=post.version)
    assert [t.locale for t in post.texts.all()] == ["sw"]


@pytest.mark.parametrize(
    ("data", "code"),
    [
        ({"tags": ["0197a000-0000-7000-8000-000000000009"]}, "unknown_reference"),
        ({"hero": "0197a000-0000-7000-8000-000000000009"}, "unknown_reference"),
        ({"type": "nonsense"}, "validation_error"),
        ({"engagement": {"likes": "maybe"}}, "validation_error"),
        ({"engagement": {"unknown": True}}, "validation_error"),
        ({"texts": {"fr": {}}}, "validation_error"),
        ({"texts": {"sw": {"body": {"version": 1, "blocks": [{"type": "html"}]}}}}, "invalid_content"),
        ({"authors": []}, "author_required"),
    ],
)
def test_bad_data_is_refused_and_nothing_changes(editor, cat, data, code):
    post = f.post(editor, cat)
    before = services.snapshot(post)
    with pytest.raises(DomainError) as e:
        services.save(actor=editor, post_id=post.pk, version=post.version, data=data)
    assert e.value.code == code
    assert services.snapshot(Post.objects.get(pk=post.pk)) == before


def test_an_article_cannot_use_a_deleted_or_wrong_file(editor, cat):
    gone = f.asset(deleted_at=timezone.now())
    clip = f.asset("video")
    post = f.post(editor, cat)
    image = {"type": "image", "id": "block-2", "asset": str(gone.pk), "alt": "a"}
    for data, code in (
        ({"texts": {"sw": {"body": f.body("a", image)}}}, "unknown_asset"),
        ({"hero": str(clip.pk)}, "wrong_asset_kind"),
    ):
        with pytest.raises(DomainError) as e:
            services.save(actor=editor, post_id=post.pk, version=post.version, data=data)
        assert e.value.code == code


# ---- publishing ------------------------------------------------------------------------------------------
def test_publish_builds_the_page_and_its_feeds(editor, cat, _quiet, django_capture_on_commit_callbacks):
    child = f.category("mikoa", cat)
    word = f.tag("uchumi")
    other = f.category("biashara")
    hero = f.asset(outputs={"variants": {"webp": {"640": "media/a.webp"}}})
    with django_capture_on_commit_callbacks(execute=True):
        post = f.post(
            editor, child, hero=str(hero.pk), tags=[str(word.pk)], secondary_categories=[str(other.pk)]
        )
        f.go(editor, post, "publish")
    row = Publication.objects.get()
    assert row.path == "/mikoa/kichwa-cha-habari"
    assert row.article["engagement"]["likes"] is True
    assert row.article["image"]["variants"] == {"webp": {"640": "media/a.webp"}}
    assert row.article["breadcrumbs"][0]["slug"] == "habari"
    feeds = set(Listing.objects.values_list("feed", "key"))
    assert feeds == {
        (Feed.ALL, ""),
        (Feed.TYPE, "article"),
        (Feed.CATEGORY, str(child.pk)),
        (Feed.CATEGORY, str(cat.pk)),
        (Feed.CATEGORY, str(other.pk)),
        (Feed.TAG, str(word.pk)),
        (Feed.AUTHOR, str(editor.pk)),
    }
    tags, pages = _quiet[-1]
    assert pages == [row.path]
    assert {f"post-{post.pk}", "latest", "tag-uchumi", f"category-{cat.pk}"} <= set(tags)


def test_edits_stay_invisible_until_republished(editor, cat):
    post = f.go(editor, f.post(editor, cat), "publish")
    post = services.save(
        actor=editor, post_id=post.pk, version=post.version, data={"texts": {"sw": {"headline": "Siri"}}}
    )
    assert Publication.objects.get().card["headline"] == "Kichwa cha habari"
    f.go(editor, post, "republish")
    assert Publication.objects.get().card["headline"] == "Siri"


def test_a_category_rename_does_not_leak_unpublished_edits(editor, cat):
    post = f.go(editor, f.post(editor, cat), "publish")
    services.save(
        actor=editor, post_id=post.pk, version=post.version, data={"texts": {"sw": {"headline": "Siri"}}}
    )
    modified = Publication.objects.get().modified_at
    texts = {"sw": {"name": "Taifa", "slug": "taifa"}, "en": {"name": "National", "slug": "national"}}
    taxonomy.save_category(actor=editor, category=cat, parent=None, texts=texts, version=cat.version)
    tasks.rebuild_posts([str(post.pk)])
    row = Publication.objects.get()
    assert row.card["headline"] == "Kichwa cha habari"
    assert row.path == "/taifa/kichwa-cha-habari"
    assert row.modified_at >= modified
    assert redirect_for("/habari/kichwa-cha-habari") == row.path


def test_rebuilding_without_changes_does_not_move_the_updated_time(editor, cat):
    post = f.go(editor, f.post(editor, cat), "publish")
    modified = Publication.objects.get().modified_at
    tasks.rebuild_posts([str(post.pk)])
    assert Publication.objects.get().modified_at == modified


def test_translations_point_at_each_other(editor, cat):
    post = f.post(editor, cat)
    post = services.save(
        actor=editor,
        post_id=post.pk,
        version=post.version,
        data={"texts": {"en": {"headline": "A headline", "body": f.body("Text")}}},
    )
    f.go(editor, post, "publish")
    rows = {p.locale: p for p in Publication.objects.all()}
    assert rows["en"].path == "/en/habari-en/a-headline"
    assert rows["sw"].article["translations"] == [{"locale": "en", "path": rows["en"].path}]
    assert rows["en"].article["translations"] == [{"locale": "sw", "path": rows["sw"].path}]


def test_unpublish_removes_every_trace_and_return_keeps_its_date(editor, cat):
    post = f.go(editor, f.post(editor, cat), "publish")
    first = post.published_at
    post = f.go(editor, post, "unpublish")
    assert not Publication.objects.exists()
    assert not Listing.objects.exists()
    assert f.go(editor, post, "publish").published_at == first


def test_a_changed_slug_redirects(editor, cat):
    post = f.go(editor, f.post(editor, cat), "publish")
    post = services.save(
        actor=editor, post_id=post.pk, version=post.version, data={"texts": {"sw": {"slug": "Anwani Mpya!"}}}
    )
    f.go(editor, post, "republish")
    assert redirect_for("/habari/kichwa-cha-habari") == "/habari/anwani-mpya"


def test_two_posts_with_one_headline_get_different_addresses(editor, cat):
    for _ in range(3):
        f.go(editor, f.post(editor, cat), "publish")
    assert Publication.objects.values("path").distinct().count() == 3


@pytest.mark.parametrize(
    ("setup", "missing"),
    [
        (lambda p, c: p.texts.update(headline=""), "headline"),
        (lambda p, c: p.bylines.all().delete(), "author"),
        (lambda p, c: p.texts.update(body={"version": 1, "blocks": []}), "body"),
        (lambda p, c: type(c).objects.filter(pk=c.pk).update(visibility="archived"), "category"),
        (lambda p, c: Post.objects.filter(pk=p.pk).update(type="short"), "video"),
        (lambda p, c: Post.objects.filter(pk=p.pk).update(type="youtube"), "youtube"),
        (lambda p, c: Post.objects.filter(pk=p.pk).update(hero=f.asset(status="processing")), "media"),
        (lambda p, c: Post.objects.filter(pk=p.pk).update(hero=f.asset(credit="")), "credit"),
        (lambda p, c: Post.objects.filter(pk=p.pk).update(hero=f.asset(alt_sw="")), "alt"),
    ],
)
def test_incomplete_posts_are_not_published(editor, cat, setup, missing):
    post = f.post(editor, cat)
    setup(post, cat)
    with pytest.raises(DomainError) as e:
        services.transition(actor=editor, post_id=post.pk, key="publish", version=post.version)
    assert missing in e.value.extra["missing"]
    assert not Publication.objects.exists()


def test_engagement_follows_post_then_category_then_global_then_kill(editor, cat):
    child = f.category("siasa", cat, engagement={"comments": "premoderated"})
    type(cat).objects.filter(pk=cat.pk).update(engagement={"comments": "verified", "reposts": True})
    post = f.post(editor, child, engagement={"likes": False})
    f.go(editor, post, "publish")
    policy = Publication.objects.get().article["engagement"]
    assert policy["comments"] == "premoderated"
    assert policy["reposts"] is True
    assert policy["likes"] is False
    SettingsSection.objects.create(
        key="engagement", version=1, data={"kill": {"comments": True, "shares": True}}
    )
    tasks.rebuild_posts([str(post.pk)])
    policy = Publication.objects.get().article["engagement"]
    assert policy["comments"] == "closed"
    assert policy["shares"] is False


# ---- scheduling ------------------------------------------------------------------------------------------
def test_scheduled_posts_go_out_on_time_and_once(editor, cat):
    post = f.post(editor, cat)
    when = timezone.now() + timedelta(minutes=5)
    services.transition(
        actor=editor, post_id=post.pk, key="schedule", version=post.version, scheduled_at=when
    )
    assert services.publish_due(when - timedelta(seconds=1)) == 0
    assert services.publish_due(when) == 1
    assert services.publish_due(when) == 0
    assert Post.objects.get().status == Status.PUBLISHED
    assert AuditEntry.objects.get(action="post.publish").actor_label == "scheduler"


def test_one_broken_scheduled_post_does_not_hold_up_the_rest(editor, cat):
    when = timezone.now() + timedelta(minutes=5)
    posts = [f.post(editor, cat, headline=f"Habari {i}") for i in range(3)]
    for post in posts:
        services.transition(
            actor=editor, post_id=post.pk, key="schedule", version=post.version, scheduled_at=when
        )
    posts[0].bylines.all().delete()
    assert services.publish_due(when) == 2
    posts[0].refresh_from_db()
    assert posts[0].status == Status.APPROVED
    entry = AuditEntry.objects.get(action="post.schedule_failed")
    assert entry.after["error"] == "not_ready"


@pytest.mark.parametrize("minutes", [-1, 0])
def test_schedule_must_be_in_the_future(editor, cat, minutes):
    post = f.post(editor, cat)
    with pytest.raises(DomainError):
        services.transition(
            actor=editor,
            post_id=post.pk,
            key="schedule",
            version=post.version,
            scheduled_at=timezone.now() + timedelta(minutes=minutes),
        )


def test_embargo_blocks_publishing_by_hand_and_by_clock(editor, cat):
    until = timezone.now() + timedelta(hours=1)
    post = f.post(editor, cat, embargo_until=until)
    with pytest.raises(Conflict) as e:
        services.transition(actor=editor, post_id=post.pk, key="publish", version=post.version)
    assert e.value.code == "embargoed"
    with pytest.raises(DomainError) as e2:
        services.transition(
            actor=editor,
            post_id=post.pk,
            key="schedule",
            version=post.version,
            scheduled_at=until - timedelta(minutes=1),
        )
    assert e2.value.code == "embargoed"


def test_every_transition_is_audited(editor, cat):
    post = f.go(editor, f.post(editor, cat), "publish", "unpublish", "archive", "restore")
    actions = set(AuditEntry.objects.filter(target_id=str(post.pk)).values_list("action", flat=True))
    assert {"post.created", "post.saved", "post.publish", "post.unpublish", "post.archive"} <= actions


def test_publishing_needs_a_bounded_number_of_queries(editor, cat, django_assert_max_num_queries):
    tags = [str(f.tag(f"t{i}").pk) for i in range(8)]
    post = f.post(editor, cat, tags=tags)
    with django_assert_max_num_queries(75):
        f.go(editor, post, "publish")


def test_listeners_hear_about_transitions(editor, cat, django_capture_on_commit_callbacks, monkeypatch):
    heard = []
    monkeypatch.setattr(services, "_listeners", [lambda p, s, a: heard.append((s.key, a))])
    with django_capture_on_commit_callbacks(execute=True):
        f.go(editor, f.post(editor, cat), "publish")
    assert heard == [("publish", editor)]
    assert publishing.ready_texts(Post.objects.get())
