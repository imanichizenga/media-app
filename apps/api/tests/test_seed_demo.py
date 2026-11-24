import pytest
from django.core.management import CommandError, call_command
from moto.server import ThreadedMotoServer

from newsplatform.content import blocks, publishing
from newsplatform.content.models import AuthorProfile, Listing, Post, PostText, PostType, Publication
from newsplatform.media import storage as storage_module
from newsplatform.media.models import Asset
from newsplatform.taxonomy.models import Category

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
        call_command("seed_demo", posts=40, images=7, videos=2)
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
    assert Listing.objects.filter(feed="all").count() == Publication.objects.count()
