"""Real responses must match the published OpenAPI schema: clients are generated from it."""

import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

from tests.test_integrations import save

pytestmark = pytest.mark.django_db
SPEC = json.loads((Path(__file__).parents[2] / "support/docs/api/openapi-admin.json").read_text())


def assert_matches(path, method, status, body):
    content = SPEC["paths"][f"/api/v1/{path}"][method]["responses"][str(status)]["content"]
    schema = {**content["application/json"]["schema"], "components": SPEC["components"]}
    errors = list(Draft202012Validator(schema).iter_errors(body))
    assert not errors, [(list(e.path), e.message[:120]) for e in errors]


@pytest.mark.parametrize(
    "path",
    [
        "auth/session",
        "me/security",
        "staff",
        "roles",
        "audit",
        "approvals",
        "logs/auth",
        "logs/integrations",
        "integrations",
        "integrations/{key}",
        "settings/{key}",
        "brand",
        "brand/versions",
    ],
)
def test_get(admin_api, path):
    _, a = admin_api()
    save(a)
    a.post("staff/invites", {"email": "j@example.test", "grants": [{"role": "journalist"}]})
    key = "localization" if path.startswith("settings") else "aws_s3"
    res = a.get(path.replace("{key}", key))
    assert res.status_code == 200
    assert_matches(path, "get", 200, res.json())


def test_cursor_walks_every_row_once(admin_api):
    _, a = admin_api()
    for i in range(7):
        a.post("staff/invites", {"email": f"p{i}@example.test", "grants": [{"role": "journalist"}]})
    seen, cursor = [], None
    while True:
        page = a.get("audit?page_size=3" + (f"&cursor={cursor}" if cursor else "")).json()
        seen += [r["seq"] for r in page["results"]]
        cursor = page["next_cursor"]
        if not cursor:
            break
    assert seen == sorted(set(seen), reverse=True) and seen[-1] == 1 and len(seen) == seen[0]
