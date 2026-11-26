import itertools

import pytest
from django.core.management import CommandError, call_command
from moto.server import ThreadedMotoServer

from newsplatform.content import blocks, publishing
from newsplatform.content.demo.texts import RAIL_TITLES
from newsplatform.content.models import AuthorProfile, Listing, Post, PostText, PostType, Publication
from newsplatform.media import storage as storage_module
from newsplatform.media.models import Asset
from newsplatform.taxonomy.models import Category, CategoryText

pytestmark = pytest.mark.django_db


def test_never_where_readers_are(settings):
    settings.IS_DEPLOYED = True
    with pytest.raises(CommandError):
        call_command("seed_demo")


def test_never_over_real_content(db, monkeypatch):
    monkeypatch.setattr(Post.objects, "exists", lambda: True)
    with pytest.raises(CommandError):
        call_command("seed_demo")


def test_demo_content_is_complete_and_publishable(settings, capsys):
    server = ThreadedMotoServer(port=0)
    server.start()
    settings.STORAGE_ENDPOINT_URL = "http://{}:{}".format(*server.get_host_and_port())
    settings.LOCAL_SCANNER, settings.LOCAL_TRANSCODER = "eicar", True
    storage_module._local.cache_clear()
    try:
        call_command("seed_demo", posts=40, images=10, videos=2)
    finally:
        server.stop()
        storage_module._local.cache_clear()
    assert Post.objects.count() == 40
    assert set(Publication.objects.values_list("type", flat=True)) >= {
        PostType.ARTICLE,
        PostType.VIDEO,
        PostType.SHORT,
        PostType.GALLERY,
        PostType.YOUTUBE,
        PostType.OPINION,
        PostType.LIVE_BLOG,
    }
    assert set(Publication.objects.values_list("locale", flat=True)) == {"sw", "en"}
    assert Category.objects.filter(parent=None).count() == 12
    assert AuthorProfile.objects.filter(avatar__isnull=False).count() == 15
    assert set(Post.objects.values_list("status", flat=True)) >= {
        "draft",
        "submitted",
        "scheduled",
        "published",
    }
    for text in PostText.objects.all():
        blocks.validate(text.body)
    for post in Post.objects.exclude(status="draft"):
        assert publishing.problems(post) == []
    assert not Asset.objects.filter(credit="").exists()
    _no_picture_beside_itself()
    texts = CategoryText.objects.filter(short_name__gt="")
    assert texts.count() == 2
    assert all(len(x.short_name) <= 14 < len(x.name) for x in texts)
    live = Publication.objects.filter(type=PostType.LIVE_BLOG)
    assert {p.card["rail_title"] for p in live} & {sw for sw, _ in RAIL_TITLES} | {
        en for _, en in RAIL_TITLES
    }
    assert all(len(p.card["rail_title"]) <= 24 for p in Publication.objects.all())


def _no_picture_beside_itself():
    """In every list readers scroll (home's rows and carousels, the rail, a section, a type) neighbours differ (R4)."""

    def pictures(rows):
        return [(r.card["image"] or {}).get("id") for r in rows]

    lists = []
    for locale in ("sw", "en"):
        for feed, key in (
            Listing.objects.filter(locale=locale, feed__in=["all", "type", "category"])
            .values_list("feed", "key")
            .distinct()
        ):
            rows = Listing.objects.filter(locale=locale, feed=feed, key=key).order_by(
                "-published_at", "-publication_id"
            )
            lists.append(
                (
                    f"{locale} {feed} {key}",
                    pictures(r.publication for r in rows.select_related("publication")),
                )
            )
        live = Publication.objects.filter(locale=locale, is_live=True).order_by("-published_at")
        lists.append((f"{locale} rail", pictures(live)))
    assert len(lists) > 20
    for name, ids in lists:
        beside = [(a, b) for a, b in itertools.pairwise(ids) if a and a == b]
        assert beside == [], name


def test_too_few_pictures_to_keep_neighbours_apart(settings):
    settings.IS_DEPLOYED = False
    with pytest.raises(CommandError, match="pictures"):
        call_command("seed_demo", posts=5, images=9, videos=0)
    assert Listing.objects.filter(feed="all").count() == Publication.objects.count()
