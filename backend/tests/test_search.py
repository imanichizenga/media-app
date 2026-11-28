"""Search (ADR-0049): what readers find, in what order, and that the index follows publishing.

The Postgres engine is tested everywhere. The OpenSearch tests run against a real engine when TEST_OPENSEARCH_URL is
set (CI starts OpenSearch 3.7 for them); without it they are skipped, and the CI job fails if they were skipped there.
"""

import os
from datetime import timedelta

import pytest
from django.test import Client
from django.utils import timezone

from newsplatform.content import publishing, services, tasks
from newsplatform.content.models import Publication
from newsplatform.search import client, engine, indexing, mapping
from tests import factories as f
from tests.test_public_api import matches_contract

pytestmark = pytest.mark.django_db
OPENSEARCH = os.environ.get("TEST_OPENSEARCH_URL", "")


@pytest.fixture(autouse=True)
def _public(settings, monkeypatch):
    settings.ROOT_URLCONF = "config.urls_public"
    settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "IpAllowlist" not in m]
    settings.OPENSEARCH_URL = ""
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: None)


@pytest.fixture
def editor(make_staff):
    return make_staff("editor_in_chief")


@pytest.fixture
def cat(db):
    return f.category("habari")


def story(editor, cat, sw, en=None, *, body="Aya ya kwanza.", type="article", minutes_ago=0, **data):
    row = services.create(actor=editor, type=type, category=cat, locale="sw", headline=sw)
    texts = {"sw": {"headline": sw, "standfirst": "Utangulizi", "body": f.body(body)}}
    if en:
        texts["en"] = {"headline": en, "standfirst": "Introduction", "body": f.body(body)}
    row = services.save(actor=editor, post_id=row.pk, version=row.version, data={"texts": texts, **data})
    services.release_lock(actor=editor, post_id=row.pk)
    row = f.go(editor, row, "publish")
    if minutes_ago:
        row.published_at = timezone.now() - timedelta(minutes=minutes_ago)
        row.save()
        publishing.publish(row)
    return row


def find(q, locale="sw", **params):
    query = "&".join(f"{k}={v}" for k, v in {"q": q, "locale": locale, **params}.items())
    res = Client().get(f"/api/v1/content/search?{query}")
    assert res.status_code == 200, res.content
    return res.json()


def headlines(answer):
    return [r["card"]["headline"] for r in answer["results"]]


# ---- what readers find (Postgres) ---------------------------------------------------------------------------


def test_words_typos_first_letters_and_english_stems(editor, cat):
    story(editor, cat, "Kampeni ya chanjo Mbeya yavuka lengo", "Mbeya vaccination campaign passes its target")
    story(editor, cat, "Wakazi wa Mwanza wapata maji safi", "Mwanza residents get clean water")
    story(editor, cat, "Bei ya mahindi yashuka Kigoma")
    assert headlines(find("chanjo")) == ["Kampeni ya chanjo Mbeya yavuka lengo"]
    assert headlines(find("chamjo")) == ["Kampeni ya chanjo Mbeya yavuka lengo"]  # one wrong letter
    assert headlines(find("mwan")) == ["Wakazi wa Mwanza wapata maji safi"]  # as it is typed
    assert headlines(find("vaccines", "en")) == ["Mbeya vaccination campaign passes its target"]
    assert headlines(find("xyzzy")) == []
    answer = find("chanjo")
    assert answer["available"] is True and answer["engine"] == "fallback"


def test_a_correct_word_does_not_bring_look_alikes(editor, cat):
    for i in range(6):
        story(editor, cat, f"Kampeni ya chanjo {i}")
    story(editor, cat, "Chakula cha mchana shuleni")
    assert all("chanjo" in h for h in headlines(find("chanjo")))


def test_the_body_and_the_writer_are_searched(editor, cat):
    story(editor, cat, "Habari ya leo", body="Mkutano wa wavuvi ulifanyika Bagamoyo jana.")
    assert headlines(find("wavuvi")) == ["Habari ya leo"]


def test_only_what_is_published_and_due(editor, cat):
    row = story(editor, cat, "Bandari mpya yafunguliwa")
    assert headlines(find("bandari")) == ["Bandari mpya yafunguliwa"]
    Publication.objects.filter(post=row).update(published_at=timezone.now() + timedelta(hours=1))
    assert headlines(find("bandari")) == []
    Publication.objects.filter(post=row).update(published_at=timezone.now() - timedelta(minutes=1))
    publishing.withdraw(row)
    assert headlines(find("bandari")) == []


def test_filters_type_section_with_its_subsections_and_period(editor, cat):
    sub = f.category("siasa", parent=cat)
    other = f.category("michezo")
    story(editor, sub, "Uchaguzi wa Mbeya leo")
    story(editor, other, "Mbeya City yashinda leo")
    story(editor, cat, "Mbeya kwa picha leo", type="gallery")
    story(editor, cat, "Mbeya zamani leo", minutes_ago=60 * 24 * 10)
    assert set(headlines(find("mbeya", category="habari"))) == {
        "Uchaguzi wa Mbeya leo",
        "Mbeya kwa picha leo",
        "Mbeya zamani leo",
    }
    assert headlines(find("mbeya", type="gallery")) == ["Mbeya kwa picha leo"]
    assert "Mbeya zamani leo" not in headlines(find("mbeya", since="7d"))
    assert headlines(find("mbeya", sort="newest"))[-1] == "Mbeya zamani leo"


def test_pages_follow_a_cursor_without_repeating(editor, cat):
    for i in range(engine.PAGE + 5):
        story(editor, cat, f"Ripoti ya mvua namba {i}", minutes_ago=i + 1)
    first = find("mvua")
    second = find("mvua", cursor=first["next_cursor"])
    assert len(first["results"]) == engine.PAGE and len(second["results"]) == 5
    assert not set(headlines(first)) & set(headlines(second))
    assert second["next_cursor"] is None and second["total_is_exact"] is True


@pytest.mark.parametrize(
    "params", [{"type": "nothing"}, {"category": "hakuna"}, {"since": "forever"}, {"sort": "random"}]
)
def test_unknown_filters_are_refused(editor, cat, params):
    query = "&".join(f"{k}={v}" for k, v in params.items())
    assert Client().get(f"/api/v1/content/search?q=a&{query}").status_code == 400


def test_queries_are_normalised_and_bounded(editor, cat):
    story(editor, cat, "Maji safi Mwanza")
    assert find("  maji\t\x00 safi  ")["query"] == "maji safi"
    assert len(find("a" * 500)["query"]) == engine.MAX_QUERY
    assert find("")["results"] == []


def test_answers_match_the_contract_and_are_cached_briefly(editor, cat):
    story(editor, cat, "Maji safi Mwanza")
    res = Client().get("/api/v1/content/search?q=maji")
    matches_contract("search", res.json())
    assert "s-maxage=60" in res["Cache-Control"] and "latest" in res["Surrogate-Key"].split()
    res = Client().get("/api/v1/content/search/suggest?q=maj")
    matches_contract("search/suggest", res.json())
    assert [s["headline"] for s in res.json()["results"]] == ["Maji safi Mwanza"]


def test_suggestions_need_two_letters(editor, cat):
    story(editor, cat, "Maji safi Mwanza")
    assert Client().get("/api/v1/content/search/suggest?q=m").json()["results"] == []


def test_the_vector_is_written_while_publishing(editor, cat):
    row = story(editor, cat, "Maji safi Mwanza")
    assert Publication.objects.get(post=row).search_vector is not None


def test_snippets_are_segments_not_markup():
    marked = f"Mji wa {engine.HIT}Mwanza{engine.END} leo <b>"
    assert engine.segments(marked) == [
        {"text": "Mji wa ", "hit": False},
        {"text": "Mwanza", "hit": True},
        {"text": " leo <b>", "hit": False},
    ]


def test_a_word_spelled_right_does_not_mark_its_look_alikes():
    parts = engine.segments(
        f"Mpaka {engine.HIT}wakati{engine.END} huo, {engine.HIT}wakazi{engine.END} wanasema"
    )
    assert engine.plain_marks(parts, "Wakazi Mbeya") == [
        {"text": "Mpaka wakati huo, ", "hit": False},
        {"text": "wakazi", "hit": True},
        {"text": " wanasema", "hit": False},
    ]
    # A mistake of the reader's own: the look-alike is all there is, so it stays marked.
    typo = engine.segments(f"Kampeni ya {engine.HIT}chanjo{engine.END}")
    assert engine.plain_marks(typo, "chamjo") == typo
    # First letters and accents count as the word.
    assert engine.plain_marks(engine.segments(f"{engine.HIT}Mwanza{engine.END}"), "mwan")[0]["hit"]
    assert engine.plain_marks(engine.segments(f"{engine.HIT}Ufaransa{engine.END}"), "ufaránsa")[0]["hit"]


def test_a_broken_cursor_starts_again():
    assert engine._decode("not-a-cursor") == (None, 1)


# ---- the breaker ---------------------------------------------------------------------------------------------


def test_the_breaker_opens_after_three_failures_and_closes_after_its_cool_down():
    b = client.Breaker(limit=3, window=30, cool=0.05)
    for _ in range(3):
        b.failure()
    assert not b.allow()
    import time

    time.sleep(0.06)
    assert b.allow()
    b.success()
    assert b.allow()


def test_an_engine_that_does_not_answer_falls_back_to_postgres(editor, cat, settings):
    story(editor, cat, "Maji safi Mwanza")
    settings.OPENSEARCH_URL = "http://127.0.0.1:9"  # nothing listens there
    client._clients.clear()
    answer = find("maji")
    assert answer["engine"] == "fallback" and headlines(answer) == ["Maji safi Mwanza"]
    client._clients.clear()


# ---- OpenSearch ----------------------------------------------------------------------------------------------

# Skipped only off CI: in CI a missing engine fails these tests instead of hiding them.
engine_only = pytest.mark.skipif(
    not OPENSEARCH and not os.environ.get("CI"), reason="TEST_OPENSEARCH_URL is not set"
)


@pytest.fixture
def opensearch(settings, monkeypatch):
    # The test's transaction never commits, so what publishing queues after commit runs at once, as it would.
    monkeypatch.setattr(publishing.transaction, "on_commit", lambda fn, robust=False: fn())
    settings.OPENSEARCH_URL = OPENSEARCH
    settings.OPENSEARCH_SIGV4 = False
    settings.OPENSEARCH_PREFIX = f"test-{os.getpid()}"
    settings.OPENSEARCH_SHARDS, settings.OPENSEARCH_REPLICAS = 1, 0
    client._clients.clear()
    client.breaker.success()
    for locale in mapping.LOCALES:
        indexing.reindex(locale)
    yield
    client.call("DELETE", f"/{settings.OPENSEARCH_PREFIX}-*", read=False, ok=(404,))
    client._clients.clear()


def refresh():
    for locale in mapping.LOCALES:
        client.call("POST", f"/{mapping.alias(locale)}/_refresh", read=False)


@engine_only
def test_opensearch_finds_words_typos_first_letters_and_stems(editor, cat, opensearch):
    story(editor, cat, "Kampeni ya chanjo Mbeya yavuka lengo", "Mbeya vaccination campaign passes its target")
    story(editor, cat, "Wakazi wa Mwanza wapata maji safi", "Mwanza residents get clean water")
    refresh()
    answer = find("chanjo")
    assert answer["engine"] == "opensearch"
    assert headlines(answer) == ["Kampeni ya chanjo Mbeya yavuka lengo"]
    assert headlines(find("chamjo")) == ["Kampeni ya chanjo Mbeya yavuka lengo"]
    assert headlines(find("mwan")) == ["Wakazi wa Mwanza wapata maji safi"]
    assert headlines(find("vaccines", "en")) == ["Mbeya vaccination campaign passes its target"]
    assert headlines(find("xyzzy")) == []


@engine_only
def test_opensearch_snippets_mark_the_words_found(editor, cat, opensearch):
    story(editor, cat, "Habari ya leo", body="Mkutano wa wavuvi ulifanyika Bagamoyo jana.")
    refresh()
    snippet = find("wavuvi")["results"][0]["snippet"]
    assert {"text": "wavuvi", "hit": True} in snippet


@engine_only
def test_opensearch_prefers_the_newer_story_on_a_tie(editor, cat, opensearch):
    story(editor, cat, "Mvua kubwa Dodoma", minutes_ago=60 * 24 * 60)
    story(editor, cat, "Mvua kubwa Dodoma leo")
    refresh()
    assert headlines(find("mvua kubwa dodoma"))[0] == "Mvua kubwa Dodoma leo"


@engine_only
def test_opensearch_follows_publishing_and_withdrawing(editor, cat, opensearch):
    row = story(editor, cat, "Bandari mpya yafunguliwa", "New port opens")
    refresh()
    assert headlines(find("bandari")) == ["Bandari mpya yafunguliwa"]
    assert headlines(find("port", "en")) == ["New port opens"]
    f.go(editor, row, "unpublish")
    refresh()
    assert headlines(find("bandari")) == [] and headlines(find("port", "en")) == []


@engine_only
def test_opensearch_pages_follow_search_after(editor, cat, opensearch):
    for i in range(engine.PAGE + 3):
        story(editor, cat, f"Ripoti ya mvua namba {i}", minutes_ago=i + 1)
    refresh()
    first = find("mvua")
    second = find("mvua", cursor=first["next_cursor"])
    assert len(first["results"]) == engine.PAGE and len(second["results"]) == 3
    assert not set(headlines(first)) & set(headlines(second))


@engine_only
def test_reconcile_repairs_a_missing_and_a_stale_document(editor, cat, opensearch):
    gone = story(editor, cat, "Habari ya kwanza")
    stale = story(editor, cat, "Habari ya pili")
    refresh()
    client.call("DELETE", f"/{mapping.alias('sw')}/_doc/{gone.pk}?refresh=true", read=False)
    client.call(
        "POST",
        f"/{mapping.alias('sw')}/_update/{stale.pk}?refresh=true",
        {"doc": {"etag": "old"}},
        read=False,
    )
    assert indexing.reconcile("sw") == 2
    refresh()
    assert set(headlines(find("habari"))) == {"Habari ya kwanza", "Habari ya pili"}


@engine_only
def test_reindex_swaps_the_alias_and_keeps_everything(editor, cat, opensearch):
    story(editor, cat, "Maji safi Mwanza")
    before = indexing.current("sw")
    result = indexing.reindex("sw")
    assert result["documents"] == 1 and result["previous"] == before and indexing.current("sw") != before
    assert headlines(find("maji")) == ["Maji safi Mwanza"]


def test_every_word_must_be_there_and_a_headline_comes_before_a_tag(editor, cat):
    story(editor, cat, "Shule za Mwanza zaanza mpango wa chakula")
    story(editor, cat, "Wakazi wa Mwanza wapata maji safi")
    story(editor, cat, "Soko jipya la Mbeya", tags=[str(f.tag("kilimo").pk)])
    story(editor, cat, "Kilimo cha mpunga chaimarika Mbeya")
    assert headlines(find("shule mwanza")) == ["Shule za Mwanza zaanza mpango wa chakula"]
    assert headlines(find("kilimo")) == ["Kilimo cha mpunga chaimarika Mbeya", "Soko jipya la Mbeya"]


def test_a_misspelt_word_never_brings_a_word_that_only_looks_a_little_like_it(editor, cat):
    story(editor, cat, "Barabara mpya ya Mtwara yafunguliwa")
    assert headlines(find("mpira")) == []  # football is not "new"
    assert headlines(find("mtwra")) == ["Barabara mpya ya Mtwara yafunguliwa"]


def test_the_snippet_shows_the_sentence_with_the_words(editor, cat):
    story(
        editor,
        cat,
        "Habari ya leo",
        body="Mvua ilinyesha. Mkutano wa wavuvi ulifanyika Bagamoyo jana. Asante.",
    )
    [hit] = find("wavuvi bagamoyo")["results"]
    assert "".join(s["text"] for s in hit["snippet"]) == "Mkutano wa wavuvi ulifanyika Bagamoyo jana."
    assert [s["text"] for s in hit["snippet"] if s["hit"]] == ["wavuvi", "Bagamoyo"]
