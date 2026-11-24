import pytest

from newsplatform.audit.models import AuditEntry
from newsplatform.common.errors import Conflict, DomainError, Forbidden
from newsplatform.content import tasks
from newsplatform.content.models import Post
from newsplatform.rbac.models import RoleAssignment
from newsplatform.rbac.registry import scope_ancestors
from newsplatform.seo.models import Redirect
from newsplatform.seo.paths import RESERVED, slugify
from newsplatform.seo.services import moved, moved_prefix, resolve
from newsplatform.staff_security import staff
from newsplatform.taxonomy import selectors, services
from newsplatform.taxonomy.models import Category, Tag
from tests import factories as f

pytestmark = pytest.mark.django_db


@pytest.fixture(autouse=True)
def _quiet(monkeypatch):
    monkeypatch.setattr(tasks.announce, "delay", lambda *_: None)


@pytest.fixture
def editor(make_staff):
    return make_staff("editor_in_chief")


def make(editor, name, parent=None, **kw):
    texts = {"sw": {"name": name}, "en": {"name": f"{name} en"}}
    return services.save_category(actor=editor, category=None, parent=parent, texts=texts, **kw)


def test_three_levels_and_no_more(editor):
    a = make(editor, "Moja")
    b = make(editor, "Mbili", a)
    c = make(editor, "Tatu", b)
    assert c.ancestors == [a.pk, b.pk]
    with pytest.raises(DomainError) as e:
        make(editor, "Nne", c)
    assert e.value.code == "too_deep"


def test_moving_a_branch_rewrites_every_ancestor(editor):
    a, x = make(editor, "Moja"), make(editor, "Lengo")
    b = make(editor, "Mbili", a)
    services.move_category(actor=editor, category=a, parent=x, position=0)
    b.refresh_from_db()
    assert b.ancestors == [x.pk, a.pk]
    assert b.depth == 3
    assert scope_ancestors("category", str(b.pk)) == {str(b.pk), str(a.pk), str(x.pk)}
    services.move_category(actor=editor, category=a, parent=None, position=0)
    b.refresh_from_db()
    assert (b.ancestors, b.depth) == ([a.pk], 2)
    assert Category.objects.get(pk=a.pk).position == 0


def test_no_cycles_and_no_branch_deeper_than_three(editor):
    a = make(editor, "Moja")
    b = make(editor, "Mbili", a)
    make(editor, "Tatu", b)
    other = make(editor, "Lengo")
    with pytest.raises(DomainError) as e:
        services.move_category(actor=editor, category=a, parent=b, position=0)
    assert e.value.code == "category_cycle"
    with pytest.raises(DomainError) as e:
        services.move_category(actor=editor, category=a, parent=other, position=0)
    assert e.value.code == "too_deep"


def test_reordering(editor):
    rows = [make(editor, n) for n in ("Moja", "Mbili", "Tatu")]
    services.move_category(actor=editor, category=rows[2], parent=None, position=0)
    order = list(Category.objects.order_by("position").values_list("pk", flat=True))
    assert order == [rows[2].pk, rows[0].pk, rows[1].pk]


def test_slug_change_redirects_the_section_and_everything_in_it(editor):
    c = make(editor, "Michezo")
    texts = {"sw": {"name": "Spoti", "slug": "spoti"}}
    services.save_category(actor=editor, category=c, parent=None, texts=texts, version=c.version)
    assert resolve("/michezo") == "/spoti"
    assert resolve("/michezo/simba-yashinda") == "/spoti/simba-yashinda"
    assert resolve("/michezo-mengine") is None


@pytest.mark.parametrize("slug", ["en", "api", "search", "tag"])
def test_website_addresses_are_reserved(editor, slug):
    assert slug in RESERVED
    with pytest.raises(DomainError) as e:
        services.save_category(
            actor=editor, category=None, parent=None, texts={"sw": {"name": "X", "slug": slug}}
        )
    assert e.value.code == "slug_reserved"


def test_duplicate_slug_and_stale_version(editor):
    c = make(editor, "Michezo")
    with pytest.raises(Conflict) as e:
        make(editor, "Michezo")
    assert e.value.code == "slug_taken"
    with pytest.raises(Conflict) as e:
        services.save_category(actor=editor, category=c, parent=None, texts={"sw": {"name": "X"}}, version=99)
    assert e.value.code == "stale_version"


def test_merge_moves_posts_and_addresses(editor):
    a, b = make(editor, "Kandanda"), make(editor, "Soka")
    first, second = f.post(editor, a), f.post(editor, b, secondary_categories=[str(a.pk)])
    services.merge_category(actor=editor, source=a, target=b)
    assert set(Post.objects.values_list("category", flat=True)) == {b.pk}
    assert not Post.objects.get(pk=second.pk).secondary_categories.exists()
    assert resolve("/kandanda/x") == "/soka/x"
    assert not Category.objects.filter(pk=a.pk).exists()
    assert first.pk


def test_merge_refuses_to_hand_out_rights_or_orphan_children(editor, make_staff, roles):
    a, b = make(editor, "Kandanda"), make(editor, "Soka")
    child = make(editor, "Ligi", a)
    with pytest.raises(Conflict) as e:
        services.merge_category(actor=editor, source=a, target=b)
    assert e.value.code == "category_has_children"
    f.scoped(make_staff("journalist"), roles["section_editor"], child)
    with pytest.raises(Conflict) as e:
        services.merge_category(actor=editor, source=child, target=b)
    assert e.value.code == "category_has_staff"


def test_scoped_manager_manages_their_branch_only(editor, make_staff, roles):
    a, b = make(editor, "Michezo"), make(editor, "Siasa")
    person = make_staff("journalist")
    roles["section_editor"].permissions = [*roles["section_editor"].permissions, "taxonomy.manage"]
    roles["section_editor"].save()
    f.scoped(person, roles["section_editor"], a)
    make(person, "Soka", a)
    for action in (
        lambda: make(person, "Bunge", b),
        lambda: make(person, "Mzizi"),
        lambda: services.move_category(actor=person, category=a, parent=None, position=0),
        lambda: services.move_category(actor=person, category=b, parent=a, position=0),
    ):
        with pytest.raises(Forbidden):
            action()


def test_public_tree_hides_branches_of_hidden_parents(editor):
    a = make(editor, "Siri", visibility="hidden")
    make(editor, "Ndani", a)
    c = make(editor, "Wazi")
    assert set(selectors.tree(public_only=True)) == {c.pk}
    assert len(selectors.tree()) == 3


def test_tree_takes_two_queries(editor, django_assert_num_queries):
    for i in range(12):
        make(editor, f"Kundi {i}")
    with django_assert_num_queries(2):
        nodes = selectors.tree()
        [n.name("sw") for n in nodes.values()]


def test_tag_merge_keeps_old_words_working(editor):
    a = services.save_tag(
        actor=editor, tag=None, name_sw="Uchaguzi", name_en="Election", synonyms=["kura", "Polls"]
    )
    b = services.save_tag(actor=editor, tag=None, name_sw="Uchaguzi Mkuu", name_en="General election")
    post = f.post(editor, f.category(), tags=[str(a.pk)])
    services.merge_tag(actor=editor, source=a, target=b)
    assert [t.pk for t in post.tags.all()] == [b.pk]
    for word in ("uchaguzi", "KURA", "polls", "Election"):
        assert selectors.find_tags([word])[word].pk == b.pk
    assert resolve("/tag/uchaguzi") == "/tag/uchaguzi-mkuu"
    with pytest.raises(DomainError):
        services.merge_tag(actor=editor, source=b, target=a)


def test_a_word_belongs_to_one_tag(editor):
    services.save_tag(actor=editor, tag=None, name_sw="Soka", name_en="Football", synonyms=["kandanda"])
    with pytest.raises(Conflict):
        services.save_tag(actor=editor, tag=None, name_sw="Mpira", name_en="Ball", synonyms=["Kandanda"])
    assert Tag.objects.count() == 1


# ---- redirects -------------------------------------------------------------------------------------------
def test_redirect_chains_are_flat_and_loops_impossible():
    moved("/a", "/b")
    moved("/b", "/c")
    assert dict(Redirect.objects.values_list("from_path", "to_path")) == {"/a": "/c", "/b": "/c"}
    moved("/c", "/a")  # back where it started
    assert resolve("/a") is None
    assert resolve("/b") == "/a"
    assert resolve("/c") == "/a"


def test_exact_rules_win_over_prefix_rules():
    moved_prefix("/old", "/new")
    moved("/old/special", "/elsewhere/page")
    assert resolve("/old/special") == "/elsewhere/page"
    assert resolve("/old/other") == "/new/other"


@pytest.mark.parametrize("path", ["no-slash", "/" + "a" * 400])
def test_bad_paths_are_refused(path):
    with pytest.raises(DomainError):
        resolve(path)


@pytest.mark.parametrize(
    ("text", "slug"),
    [
        ("Serikali yatangaza mpango mpya", "serikali-yatangaza-mpango-mpya"),
        ("Ng'ombe wa Rais", "ngombe-wa-rais"),
        ("Ng\u2019ombe", "ngombe"),
        ("Café & Curry — 2026!", "cafe-curry-2026"),
        ("   ", ""),
        ("القاهرة", ""),
        ("a" * 200, "a" * 80),
        ("neno " * 40, "-".join(["neno"] * 16)),
    ],
)
def test_slugify(text, slug):
    assert slugify(text) == slug


# ---- scopes ----------------------------------------------------------------------------------------------
def test_a_scope_must_exist(make_staff, editor):
    boss = make_staff("super_admin")
    with pytest.raises(DomainError) as e:
        staff.invite(
            actor=boss,
            email="a@example.test",
            grants=[{"role": "section_editor", "scope_type": "category", "scope_id": "sport"}],
        )
    assert e.value.code == "unknown_scope"


def test_approving_a_scoped_privileged_role_does_not_grant_it_everywhere(make_staff, roles, editor):
    from newsplatform.approvals import services as approvals
    from newsplatform.site_config.models import SettingsSection

    SettingsSection.objects.create(key="security", version=1, data={"four_eyes": "on"})
    cat = make(editor, "Michezo")
    boss, second, target = make_staff("super_admin"), make_staff("super_admin"), make_staff("journalist")
    request = staff.grant_role(
        actor=boss, user=target, role=roles["admin"], scope_type="category", scope_id=str(cat.pk)
    )
    approvals.approve(actor=second, req_id=request.pk)
    row = RoleAssignment.objects.get(user=target, role=roles["admin"])
    assert (row.scope_type, row.scope_id) == ("category", str(cat.pk))


def test_changes_are_audited(editor):
    c = make(editor, "Michezo")
    services.save_category(
        actor=editor, category=c, parent=None, texts={"sw": {"name": "Spoti"}}, version=c.version
    )
    entry = AuditEntry.objects.get(action="category.updated")
    assert entry.before["texts"]["sw"]["name"] == "Michezo"
    assert entry.after["texts"]["sw"]["name"] == "Spoti"


def test_a_model_rule_becomes_a_400(editor):
    from django.core.exceptions import ValidationError

    from newsplatform.common.errors import exception_handler

    with pytest.raises(ValidationError) as e:
        make(editor, "Michezo", color="red")
    response = exception_handler(e.value, {})
    assert response.status_code == 400
    assert "color" in response.data["errors"]
