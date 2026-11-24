import base64
import json
import struct
import zlib
from importlib import import_module

import pytest
from django.apps import apps
from django.db import connection
from django.test import Client, override_settings

from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit.models import AuditEntry
from newsplatform.common.errors import DomainError
from newsplatform.site_config import brand, logos, services
from newsplatform.site_config.models import BrandLogo, BrandVersion, SettingsSection

NS = 'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'
BAR = '<rect width="400" height="100" fill="#b5121b"/>'


def svg(inner=BAR, size="0 0 400 100"):
    return f'<svg {NS} viewBox="{size}">{inner}</svg>'.encode()


def png(width, height, alpha=0):
    """A red bar with a clear (or solid) margin."""
    row = b"\x00" + b"".join(
        bytes((181, 18, 27, 255 if width // 8 < x < width * 7 // 8 else alpha)) for x in range(width)
    )

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    chunks = chunk(b"IHDR", header), chunk(b"IDAT", zlib.compress(row * height)), chunk(b"IEND", b"")
    return b"\x89PNG\r\n\x1a\n" + b"".join(chunks)


def publish(api, version=0, *, note="", identity=None, **look):
    data = api.get("brand").json()["data"]
    data["appearance"].update(look)
    data["identity"].update(identity or {})
    return api.put("brand", {"version": version, "data": data, "note": note})


def upload(api, kind, data):
    return api.post("brand/logos", {"kind": kind, "content": base64.b64encode(data).decode()})


# ---- publishing -------------------------------------------------------------------------------------------
def test_publish_is_public_audited_and_versioned(admin_api, client, django_capture_on_commit_callbacks):
    _, a = admin_api()
    assert client.get("/api/v1/brand").status_code in (401, 403)
    old = a.get("brand").json()
    assert (old["version"], old["theme"]["key"], old["can_edit"]) == (0, "signature", True)
    with django_capture_on_commit_callbacks() as calls:
        res = publish(a, theme="bold", color="#8B0000", note="New look", identity={"brand_name": "Habari"})
    assert res.json() == {"version": 1, "approval_required": False}
    assert calls  # the website and the CDN are told
    config = services.public_config()
    assert config["identity"]["brand_name"] == "Habari"
    assert (config["theme"]["key"], config["theme"]["color"]) == ("bold", "#8b0000")
    assert config["theme"]["hash"] != old["theme"]["hash"]
    assert config["theme"]["theme_color"]["light"] == config["theme"]["tokens"]["light"]["masthead-bg"]
    entry = AuditEntry.objects.get(action="brand.published")
    assert entry.after == {
        "appearance.theme": "bold",
        "appearance.color": "#8b0000",
        "identity.brand_name": "Habari",
    }
    assert entry.before["appearance.theme"] == "signature"
    assert entry.reason == "New look"
    assert publish(a, 0, theme="quiet").json()["code"] == "stale_version"


def test_only_those_who_manage_settings_publish(admin_api):
    _, a = admin_api()
    data = a.get("brand").json()["data"]
    _, viewer = admin_api("analyst")
    assert viewer.put("brand", {"version": 0, "data": data}).status_code == 403
    assert viewer.post("brand/versions/1/restore", {"version": 0}).status_code == 403
    assert upload(viewer, "wordmark", svg()).status_code == 403
    assert a.put("settings/brand", {"version": 0, "values": {}}).json()["code"] == "use_appearance"


def test_publishing_asks_for_a_fresh_check():
    from newsplatform.site_config import brand_api

    assert brand_api.BrandView.step_up == ("PUT",)
    assert brand_api.BrandRestoreView.step_up == ("POST",)


def test_unreadable_colour_is_refused_with_reasons_and_a_way_out(admin_api):
    _, a = admin_api()
    res = publish(a, color="#ffcc00")
    body = res.json()
    assert (res.status_code, body["code"], body["field"]) == (400, "contrast", "color")
    assert {"theme", "scheme", "fg", "bg", "ratio", "min"} == set(body["failures"][0])
    assert publish(a, color=body["nearest"]).status_code == 200
    body = publish(a, 1, color="#b5121b", dark_color="#400000").json()
    assert body["field"] == "dark_color"
    assert publish(a, 1, color="#b5121b", dark_color=body["nearest"]).status_code == 200
    assert services.public_config()["theme"]["tokens"]["dark"]["brand-text"] == body["nearest"]
    assert publish(a, 2, color="red").status_code == 400
    assert publish(a, 2, theme="neon").status_code == 400


def test_four_eyes_version_history_and_rollback(admin_api):
    _, a = admin_api()
    _, b = admin_api("super_admin")
    publish(a, theme="quiet")
    first = services.public_config()["theme"]["hash"]
    values = a.get("settings/security").json()["values"]
    a.put("settings/security", {"version": 0, "values": {**values, "four_eyes": "on"}})
    assert publish(a, 1, theme="bold").json() == {"version": 1, "approval_required": True}
    assert a.get("brand").json()["approval_pending"] is True
    assert publish(a, 1, theme="signature").json()["code"] == "approval_pending"
    req = ApprovalRequest.objects.get(action="brand.publish")
    assert a.post(f"approvals/{req.pk}/approve", {}).status_code == 403
    assert services.public_config()["theme"]["key"] == "quiet"
    assert b.post(f"approvals/{req.pk}/approve", {}).status_code == 200
    assert services.public_config()["theme"]["key"] == "bold"
    # Back with one click, and a second person again.
    assert a.post("brand/versions/1/restore", {"version": 2}).json()["approval_required"] is True
    req = ApprovalRequest.objects.get(action="brand.publish", status="pending")
    assert b.post(f"approvals/{req.pk}/approve", {}).status_code == 200
    assert services.public_config()["theme"]["hash"] == first
    rows = a.get("brand/versions").json()["results"]
    assert [(r["number"], r["restored_from"]) for r in rows] == [(3, 1), (2, None), (1, None)]
    assert rows[0]["approved_by"]["display_name"]
    assert AuditEntry.objects.get(action="brand.restored").after["restored_from"] == 1
    assert a.post("brand/versions/99/restore", {"version": 3}).status_code == 404


# ---- delivery ---------------------------------------------------------------------------------------------
def test_stylesheet_is_immutable_and_changes_address_on_publish(admin_api, client):
    _, a = admin_api()
    old = services.public_config()["theme"]["css"]
    assert client.get(old).status_code == 200  # before anything was ever published
    publish(a, theme="bold")
    path = services.public_config()["theme"]["css"]
    assert path != old
    res = client.get(path)
    assert res["Content-Type"].startswith("text/css")
    assert "immutable" in res["Cache-Control"]
    text = res.content.decode()
    assert text.count("--color-masthead-bg: #0b0b0c;") == 3
    res = client.get("/theme/current.css")
    assert (res.status_code, res["Location"], res["Cache-Control"]) == (302, path, "no-cache")
    publish(a, 1, theme="quiet")
    assert client.get(path).content.decode() == text  # a page cached yesterday keeps its colours
    missing = client.get("/theme/0123456789abcdef.css")
    assert (missing.status_code, missing["Cache-Control"]) == (404, "no-store")
    for m in ("sw", "en"):
        body = json.loads(client.get(f"/theme/manifest-{m}.webmanifest").content)
        assert (body["lang"], body["theme_color"]) == (m, "#f9f6ef")


@pytest.mark.django_db
def test_public_surface_serves_the_theme():
    with override_settings(ROOT_URLCONF="config.urls_public"):
        config = Client().get("/api/v1/site-config").json()
        assert Client().get(config["theme"]["css"]).status_code == 200
        assert Client().get("/theme/manifest-sw.webmanifest").status_code == 200
    assert BrandVersion.objects.count() == 0


# ---- logos ------------------------------------------------------------------------------------------------
SCRIPT_HTML = '<foreignObject><body xmlns="http://www.w3.org/1999/xhtml"><iframe src="javascript:1"/></body></foreignObject>'
MALICIOUS = {
    "script": "<script>alert(1)</script>",
    "onload": '<rect width="9" height="9" onload="alert(1)" onclick="x()"/>',
    "xlink javascript": '<a xlink:href="javascript:alert(1)"><rect width="9" height="9"/></a>',
    "use external": '<use href="https://evil.example/x.svg#a"/><use xlink:href="//evil.example/a#b"/>',
    "use javascript": '<use xlink:href="javascript:alert(1)"/>',
    "image external": '<image href="https://evil.example/pixel.png" width="9" height="9"/>',
    "image svg data": '<image href="data:image/svg+xml;base64,PHN2Zz4=" width="9" height="9"/>',
    "data on use": '<use href="data:image/png;base64,AAAA"/>',
    "foreignObject": SCRIPT_HTML,
    "css url": '<rect width="9" height="9" fill="url(https://evil.example/a.svg#g)"/>',
    "style url": '<rect width="9" height="9" style="fill:url(//evil.example);behavior:url(x)"/>',
    "animate": '<animate attributeName="href" to="javascript:alert(1)"/><set attributeName="onload" to="x"/>',
    "handler": '<handler type="text/javascript">x</handler>',
    "html": '<b xmlns="http://www.w3.org/1999/xhtml" onclick="x">x</b>',
}
BAD = ["script", "onload", "onclick", "evil", "foreignobject", "iframe", "animate", "data:", "behavior",
       "handler", "xhtml", "<set", "<a"]  # fmt: skip


@pytest.mark.parametrize("name", MALICIOUS)
def test_svg_is_rebuilt_without_anything_active(name):
    out = logos.clean_svg(svg(MALICIOUS[name] + BAR)).decode()
    assert not [bad for bad in BAD if bad in out.lower()], out
    assert 'fill="#b5121b"' in out


def test_svg_keeps_what_a_drawing_needs():
    out = logos.clean_svg(
        svg(
            '<defs><linearGradient id="g"><stop offset="0" stop-color="#f00"/></linearGradient></defs>'
            '<g style="fill:#123456;stroke-width:2"><path d="M0 0h400v100z" fill="url(#g)"/>'
            '<use xlink:href="#g"/></g>'
            '<image href="data:image/png;base64,iVBORw0KGgo=" width="4" height="4"/>'
        )
    ).decode()
    kept = ['fill="#123456"', 'stroke-width="2"', "url(#g)", 'href="#g"', "data:image/png;base64", "M0 0h400"]
    assert not [k for k in kept if k not in out], out


@pytest.mark.parametrize(
    ("data", "code"),
    [
        (b"<html/>", "logo_unreadable"),
        (b"not xml", "logo_unreadable"),
        (b'<!DOCTYPE svg [<!ENTITY a "aaaa">]>' + svg("<title>&a;</title>"), "logo_unsafe"),
        (svg("<style>rect{fill:red}</style>"), "logo_style"),
        (svg("<text>News</text>"), "logo_text"),
        (svg("<g>" * 40 + "</g>" * 40), "logo_too_complex"),
        (svg('<rect width="9" height="9"/>' * 5000), "logo_too_complex"),
        (svg(size=""), "logo_no_viewbox"),
        (svg('<rect width="100" height="100"/>', "0 0 100 100"), "logo_shape"),
        (svg('<rect width="4000" height="100"/>', "0 0 4000 100"), "logo_shape"),
        (svg(""), "logo_empty"),
        (png(400, 40), "logo_small"),
        (png(800, 200, alpha=255), "logo_opaque"),
        (png(800, 200)[:300], "logo_unreadable"),
        (b"x" * (logos.MAX_BYTES + 1), "logo_too_large"),
    ],
)
def test_bad_wordmarks_are_refused_with_a_reason(data, code):
    with pytest.raises(DomainError) as e:
        logos.make("wordmark", data)
    assert e.value.code == code


def test_renditions_are_trimmed_sharp_and_white_on_dark():
    import pyvips

    inner = '<path d="M100 25h200v50h-30v-20h-140v20h-30z" fill="#b5121b"/>'
    made = logos.make("wordmark", svg(inner))
    assert round(made.width / made.height, 1) == 4.0  # the margins are gone
    assert b'viewBox="100 25 200 50"' in made.files["logo.svg"]
    for name, height in logos.HEIGHTS.items():
        picture = pyvips.Image.new_from_buffer(made.files[f"{name}.png"], "")
        assert (picture.height, picture.hasalpha()) == (height, True)
    white = pyvips.Image.new_from_buffer(made.files["white-2x.png"], "")
    assert white(10, 5)[:3] == [255, 255, 255]
    made = logos.make("symbol", svg('<circle cx="50" cy="50" r="50"/>', "0 0 100 100"))
    assert pyvips.Image.new_from_buffer(made.files["large.png"], "").width == 512
    with pytest.raises(DomainError):
        logos.make("symbol", png(800, 200))


LOGO = '<path d="M0 0h400v100h-60v-60h-280v60h-60z" fill="#b5121b"/>'


def test_upload_publish_and_serve(admin_api, client):
    _, a = admin_api()
    res = upload(a, "wordmark", svg(LOGO))
    assert res.status_code == 200, res.content
    logo, white = res.json()["logo"], res.json()["white"]
    assert upload(a, "wordmark", svg(LOGO)).json()["logo"]["id"] == logo["id"]  # the same file is one logo
    assert BrandLogo.objects.count() == 1
    assert a.post("brand/logos", {"kind": "wordmark", "content": "%%%"}).status_code == 400
    assert upload(a, "wordmark", svg("<text>a</text>")).json()["code"] == "logo_text"
    assert publish(a, identity={"symbol": logo["id"]}).status_code == 400  # a wordmark is not a symbol
    assert publish(a, identity={"wordmark_light": logo["id"]}).status_code == 200
    body = services.public_config()["identity"]
    assert body["wordmark_dark"] == white
    assert white["derived"] is True
    served = client.get(body["wordmark_light"]["svg"])
    assert (served.status_code, served["Content-Type"]) == (200, "image/svg+xml")
    assert "sandbox" in served["Content-Security-Policy"]
    assert "immutable" in served["Cache-Control"]
    assert client.get(white["png"]["2x"])["Content-Type"] == "image/png"
    assert client.get("/theme/logo/wordmark-" + "0" * 32 + "/1x.png").status_code == 404
    assert AuditEntry.objects.filter(action="brand.logo_uploaded").count() == 1


# ---- migration --------------------------------------------------------------------------------------------
@pytest.mark.django_db
@pytest.mark.parametrize(
    ("old", "look"),
    [
        ({}, {}),
        ({"accent_light": "#0b5cad", "accent_dark": "#7db8f5"}, {}),
        ({"accent_light": "#AA0011"}, {"color": "#aa0011"}),
        (
            {"accent_light": "#aa0011", "accent_dark": "#ff9999"},
            {"color": "#aa0011", "dark_color": "#ff9999"},
        ),
    ],
)
def test_old_identity_is_carried_over_and_left_alone(old, look):
    old = {"brand_name": "Jina", **old}
    SettingsSection.objects.create(key="identity", data=old)
    import_module("newsplatform.site_config.migrations.0002_brand").carry_over(apps, connection)
    row = SettingsSection.objects.get(key="brand")
    assert row.data == {"identity": {"brand_name": "Jina"}, "appearance": look}
    assert SettingsSection.objects.get(key="identity").data == old
    assert services.brand_name() == "Jina"
    current = services.get_brand()[0].appearance
    brand.check_color(current.color, current.dark_color)


# ---- email ------------------------------------------------------------------------------------------------
@pytest.mark.django_db
def test_email_wears_the_brand_and_escapes_everything():
    from newsplatform.integrations.providers.ses import branded

    SettingsSection.objects.create(
        key="brand", data={"identity": {"brand_name": "A & <b>"}, "appearance": {"theme": "bold"}}
    )
    html = branded("Hi", 'Open https://admin.example/invite#t=1&x="y"\n\n<script>')
    assert "A &amp; &lt;b&gt;" in html
    assert "background:#0b0b0c" in html
    assert 'href="https://admin.example/invite#t=1&amp;x="' in html
    assert "<script>" not in html
    assert "<img" not in html
