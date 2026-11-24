import json
from pathlib import Path

import pytest

from newsplatform.common.errors import DomainError
from newsplatform.content import blocks

ROOT = Path(__file__).parents[2]
FIXTURES = ROOT / "support/docs/content-fixtures"


def load(kind):
    return [pytest.param(json.loads(f.read_text()), id=f.stem) for f in sorted((FIXTURES / kind).iterdir())]


@pytest.mark.parametrize("document", load("valid"))
def test_valid_fixtures_are_accepted(document):
    assert blocks.validate(document) is document


@pytest.mark.parametrize("document", load("invalid"))
def test_invalid_fixtures_are_refused(document):
    with pytest.raises(DomainError) as e:
        blocks.validate(document)
    assert e.value.code == "invalid_content"
    assert e.value.extra["errors"]


def test_the_api_validates_with_the_shared_schema():
    ours = Path(blocks.__file__).parent / "schema/content.v1.json"
    shared = ROOT / "support/packages/content-schema/schema/content.v1.json"
    assert ours.read_bytes() == shared.read_bytes()


def test_errors_point_at_the_problem():
    bad = {"version": 1, "blocks": [{"type": "image", "id": "block-1", "asset": "x", "alt": "a"}]}
    with pytest.raises(DomainError) as e:
        blocks.validate(bad)
    assert e.value.extra["errors"][0]["field"] == "blocks.0.asset"


def test_size_is_limited_before_anything_is_parsed():
    with pytest.raises(DomainError) as e:
        blocks.validate({"version": 1, "blocks": [], "x": "a" * blocks.MAX_BYTES})
    assert e.value.code == "content_too_large"


def test_validation_stays_fast_for_a_long_article():
    import time

    text = {"type": "text", "text": "a" * 900}
    doc = {
        "version": 1,
        "blocks": [{"type": "paragraph", "id": f"block-{i}", "content": [text]} for i in range(800)],
    }
    start = time.perf_counter()
    blocks.validate(doc)
    assert time.perf_counter() - start < 2


def test_helpers():
    doc = json.loads((FIXTURES / "valid/all-blocks.json").read_text())
    assert len(blocks.asset_ids(doc)) == 4
    assert "Aya ya kawaida." in blocks.plain_text(doc)
    assert blocks.reading_minutes({"version": 1, "blocks": []}) == 1
