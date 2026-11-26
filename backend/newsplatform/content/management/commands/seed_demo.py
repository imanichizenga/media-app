"""Realistic bilingual demo content: for development, screenshots and performance tests. Never in production."""

import itertools
import random
import subprocess
import tempfile
import zlib
from collections.abc import Callable
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError, CommandParser
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.content import authors, publishing, services, tasks
from newsplatform.content.demo import scenes
from newsplatform.content.demo import texts as t
from newsplatform.content.models import Listing, Post, PostType, Publication
from newsplatform.media import services as media
from newsplatform.media.models import Asset, AssetStatus
from newsplatform.media.tasks import process
from newsplatform.rbac.models import Role, RoleAssignment
from newsplatform.rbac.services import sync_system_roles
from newsplatform.seo.paths import slugify
from newsplatform.site_config.models import SettingsSection
from newsplatform.taxonomy import services as taxonomy
from newsplatform.taxonomy.models import Category, CategoryText, Region, Story, Tag

LOCALES = ("sw", "en")
# Enough that a picture never needs to stand beside itself in any list (see _picture).
FEWEST_PICTURES = 10
CREDIT = "Mchoro wa mfano / Demo illustration"
# Of every hundred posts. The rest are articles.
MIX: list[tuple[str, int]] = [
    (PostType.VIDEO, 7),
    (PostType.SHORT, 7),
    (PostType.GALLERY, 5),
    (PostType.YOUTUBE, 4),
    (PostType.OPINION, 6),
    (PostType.LIVE_BLOG, 2),
    (PostType.INSTAGRAM, 2),
    (PostType.BREAKING, 1),
]


class Command(BaseCommand):
    help = "Fill an empty development database with about 300 bilingual demo posts."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument("--posts", type=int, default=300)
        parser.add_argument("--images", type=int, default=28)
        parser.add_argument("--videos", type=int, default=6)

    def handle(self, *args: Any, **options: Any) -> None:
        if settings.IS_DEPLOYED:
            raise CommandError("Demo content is never created in a deployed environment.")
        if Post.objects.exists():
            raise CommandError("There are posts already. Demo content needs an empty database.")
        if options["images"] < FEWEST_PICTURES:
            raise CommandError(f"At least {FEWEST_PICTURES} pictures, so that none stands beside itself.")
        # Drawn from one seed, so screenshots are comparable from run to run.
        self.rng = random.Random(20261123)  # noqa: S311
        sync_system_roles()
        self.editor = self._person("Mhariri Demo", "editor_in_chief")
        # Files are processed here, so a worker must not process them again; and 300 purges say nothing.
        queued = (tasks.announce, process)
        kept = [task.delay for task in queued]
        for task in queued:
            task.delay = lambda *_: None
        try:
            self._taxonomy()
            self._media(options["images"], options["videos"])
            self._people()
            self._brand()
            self._posts(options["posts"])
            self._spread_pictures()
        finally:
            for task, delay in zip(queued, kept, strict=True):
                task.delay = delay
        self.stdout.write(f"{Post.objects.count()} posts, {Asset.objects.count()} files")

    # ---- people ------------------------------------------------------------
    def _person(self, name: str, role: str) -> User:
        user = User.objects.create_user(
            email=f"{slugify(name)}@demo.example.test", display_name=name, is_staff_member=True
        )
        RoleAssignment.objects.create(user=user, role=Role.objects.get(key=role))
        return user

    def _people(self) -> None:
        self.reporters: dict[str, User] = {}
        for i, (name, title, beat) in enumerate(t.REPORTERS):
            user = self._person(name, "journalist")
            avatar = self._image(f"picha-{slugify(name)}.jpg", scenes.portrait(i), (name, name))
            beats = self.categories.get(beat)
            words = (
                [loc.name.lower() for loc in beats.texts.order_by("-locale")] if beats else ["habari", "news"]
            )
            authors.update(
                actor=user,
                user_id=user.pk,
                data={
                    "title_sw": title[0],
                    "title_en": title[1],
                    "bio_sw": t.BIO[0].format(name=name, beat=words[0]),
                    "bio_en": t.BIO[1].format(name=name, beat=words[-1]),
                    "expertise": [title[0]],
                    "links": [f"https://example.org/{slugify(name)}"],
                    "avatar": avatar.pk,
                },
            )
            self.reporters.setdefault(beat, user)
        self.everyone = list(User.objects.filter(author__isnull=False))

    def _brand(self) -> None:
        SettingsSection.objects.update_or_create(
            key="brand",
            defaults={
                "data": {
                    "identity": {
                        "brand_name": "Mfano News",
                        "tagline_sw": "Habari za kuaminika, kila saa",
                        "tagline_en": "News you can trust, every hour",
                    }
                }
            },
        )

    # ---- sections ------------------------------------------------------------
    def _taxonomy(self) -> None:
        self.categories: dict[str, Category] = {}
        self.scenes: dict[str, list[str]] = {}
        for position, (names, slugs, icon, color, drawn, children) in enumerate(t.CATEGORIES):
            root = self._category(names, slugs, None, position, icon, color)
            self.scenes[slugs[0]] = drawn
            for i, (child_names, child_slugs, *short) in enumerate(children):
                self._category(child_names, child_slugs, root, i, "", color, short[0] if short else None)
                self.scenes[child_slugs[0]] = drawn
        for sw, en in t.PLACES:
            Region.objects.create(slug=slugify(sw), name_sw=sw, name_en=en)
        for sw, en in t.TAGS:
            taxonomy.save_tag(actor=self.editor, tag=None, name_sw=sw, name_en=en)
        for (sw, en), slug in t.STORIES:
            Story.objects.create(slug=slug, title_sw=sw, title_en=en, summary_sw=sw, summary_en=en)

    def _category(
        self,
        names: t.T,
        slugs: t.T,
        parent: Category | None,
        position: int,
        icon: str,
        color: str,
        shorts: t.T | None = None,
    ) -> Category:
        row = Category.objects.create(
            parent=parent,
            depth=2 if parent else 1,
            ancestors=[parent.pk] if parent else [],
            position=position,
            icon=icon,
            color=color,
        )
        for i, (locale, name, slug) in enumerate(zip(LOCALES, names, slugs, strict=True)):
            short = shorts[i] if shorts else ""
            CategoryText.objects.create(category=row, locale=locale, name=name, short_name=short, slug=slug)
        self.categories[slugs[0]] = row
        return row

    # ---- files ------------------------------------------------------------
    def _image(self, name: str, data: bytes, alt: t.T) -> Asset:
        return self._ingest("image", name, data, alt_sw=alt[0], alt_en=alt[1])

    def _ingest(self, kind: str, name: str, data: bytes, **details: Any) -> Asset:
        asset = media.ingest(
            actor=self.editor,
            kind=kind,
            filename=name,
            data=data,
            credit=CREDIT,
            license="Imetengenezwa na mfumo / Generated (see support/docs/content-fixtures/LICENSES.md)",
            **details,
        )
        # Here and now, rather than waiting for a worker to take it from the queue.
        process.apply(args=[str(asset.pk)])
        asset.refresh_from_db()
        if asset.status != AssetStatus.READY:
            raise CommandError(f"{name}: {asset.status} {asset.error_code} {asset.error_detail}")
        return asset

    def _media(self, images: int, videos: int) -> None:
        self.pictures: dict[str, list[Asset]] = {}
        names = list(scenes.SCENES)
        for i in range(images):
            name = names[i % len(names)]
            alt = (f"Mchoro: {name}", f"Illustration: {name}")
            asset = self._image(f"{name}-{i}.jpg", scenes.draw(name, i), alt)
            self.pictures.setdefault(name, []).append(asset)
            self.stdout.write(f"image {i + 1}/{images}")
        self.clips: dict[bool, list[Asset]] = {False: [], True: []}
        for i in range(videos):
            vertical, name = bool(i % 2), names[(i * 3) % len(names)]
            data = film(scenes.draw(name, i + 50, vertical=vertical), vertical, 8 + i)
            alt = (f"Video: {name}", f"Video: {name}")
            clip = self._ingest("video", f"{name}-{i}.mp4", data, alt_sw=alt[0], alt_en=alt[1])
            self.clips[vertical].append(clip)
            self.stdout.write(f"video {i + 1}/{videos}")

    def _picture(self, slug: str) -> Asset:
        wanted = [a for n in self.scenes[slug] for a in self.pictures.get(n, [])]
        return self.rng.choice(wanted or [a for rows in self.pictures.values() for a in rows])

    def _spread_pictures(self) -> None:
        """No picture stands beside itself in a list readers scroll (R4).

        Walked once everything is published, in each list's own order, because only then is it known who stands
        beside whom (drafts are in no list; breaking news goes to the top). The lists that must hold: home's rows and
        carousels (all), each type, each section, and the live rail, in each language. A tag's, a story's or a
        writer's list holds too whenever the pictures allow. A post whose picture its neighbour already has gets
        another and is published again."""
        strict, lesser = self._neighbours()
        everything = [a.pk for rows in self.pictures.values() for a in rows]
        posts = Post.objects.filter(publications__isnull=False).distinct().order_by("-published_at", "-pk")
        hero: dict[Any, Any] = {}
        changed = []
        for post in posts:
            must = {hero[n] for n in strict.get(post.pk, ()) if n in hero}
            rather = must | {hero[n] for n in lesser.get(post.pk, ()) if n in hero}
            pick = post.hero_id
            if pick in rather:
                ours = [a.pk for n in self.scenes.get(self._slug(post), []) for a in self.pictures.get(n, [])]
                for pool, avoid in ((ours, rather), (everything, rather), (ours, must), (everything, must)):
                    free = [x for x in pool if x not in avoid]
                    if free:
                        pick = self.rng.choice(free)
                        break
                else:  # pragma: no cover - FEWEST_PICTURES is more than any post's neighbours
                    raise CommandError("Too few pictures to keep neighbours apart.")
            hero[post.pk] = pick
            if pick != post.hero_id:
                post.hero_id = pick
                changed.append(post)
        for post in changed:
            post.save(update_fields=["hero"])
            publishing.publish(post)

    def _slug(self, post: Post) -> str:
        return next((s for s, c in self.categories.items() if c.pk == post.category_id), "")

    def _neighbours(self) -> tuple[dict[Any, set[Any]], dict[Any, set[Any]]]:
        """For each post, the posts just before it in each list it is in: (lists that must hold, the others)."""
        strict: dict[Any, set[Any]] = {}
        lesser: dict[Any, set[Any]] = {}
        post_of = dict(Publication.objects.values_list("pk", "post_id"))
        lists: dict[tuple[str, str, str], list[Any]] = {}
        rows = Listing.objects.order_by("-published_at", "-publication_id").values_list(
            "locale", "feed", "key", "publication_id"
        )
        for locale, feed, key, publication in rows:
            lists.setdefault((locale, feed, key), []).append(post_of[publication])
        for locale in LOCALES:
            rail = Publication.objects.filter(locale=locale, is_live=True).order_by("-published_at", "-pk")
            lists[(locale, "rail", "")] = list(rail.values_list("post_id", flat=True))
        for (_, feed, _), order in lists.items():
            into = strict if feed in ("all", "type", "category", "rail") else lesser
            for before, post in itertools.pairwise(order):
                into.setdefault(post, set()).add(before)
        return strict, lesser

    # ---- posts ------------------------------------------------------------
    def _posts(self, total: int) -> None:
        kinds = [k for k, share in MIX for _ in range(max(1, round(total * share / 100)))]
        if not (self.clips[True] and self.clips[False]):
            kinds = [k for k in kinds if k not in (PostType.VIDEO, PostType.SHORT)]
        kinds = (kinds + [PostType.ARTICLE] * total)[:total]
        self.rng.shuffle(kinds)
        now, at = timezone.now(), timezone.now() - timedelta(minutes=4)
        stories, tags = list(Story.objects.all()), list(Tag.objects.all())
        regions = {r.name_sw: r for r in Region.objects.all()}
        desks = [slugs[0] for _, slugs, *_ in t.CATEGORIES]
        for n, kind in enumerate(kinds):
            desk = "maoni" if kind == PostType.OPINION else self.rng.choice(desks[:-1])
            branch = [desk, *(c[0] for _, s, *_, kids in t.CATEGORIES if s[0] == desk for _, c, *_ in kids)]
            slug, place = self.rng.choice(branch), self.rng.choice(t.PLACES)
            author = self.reporters.get(desk) or self.rng.choice(self.everyone)
            head = self.rng.choice(t.HEADLINES[desk])
            # A third have no English version yet, as in a real newsroom.
            locales = LOCALES if self.rng.random() < 0.67 else ("sw",)
            post = services.create(
                actor=author, type=PostType.ARTICLE, category=self.categories[slug], locale="sw"
            )
            texts = {}
            for i, locale in enumerate(LOCALES):
                if locale in locales:
                    headline = head[i].format(p=place[i])
                    standfirst = self.rng.choice(t.STANDFIRST)[i]
                    texts[locale] = {
                        "headline": headline,
                        "standfirst": standfirst,
                        "body": self._body(kind, i, slug, n),
                        "seo_description": standfirst,
                    }
            picked = {str(x.pk) for x in self.rng.sample(tags, k=self.rng.randint(1, 3))}
            story = self.rng.choice(stories).pk if self.rng.random() < 0.18 else None
            if kind == PostType.LIVE_BLOG:
                for locale in texts:
                    texts[locale]["rail_title"] = t.RAIL_TITLES[n % len(t.RAIL_TITLES)][LOCALES.index(locale)]
            data: dict[str, Any] = {
                "type": kind,
                "texts": texts,
                "hero": self._picture(slug).pk,
                "tags": sorted(picked),
                "regions": [regions[place[0]].pk],
                "is_evergreen": self.rng.random() < 0.1,
                "story": story,
            }
            if kind in (PostType.VIDEO, PostType.SHORT) and self.clips[kind == PostType.SHORT]:
                data["video"] = self.rng.choice(self.clips[kind == PostType.SHORT]).pk
            if kind == PostType.YOUTUBE:
                data["youtube_id"], _, data["youtube_seconds"] = t.YOUTUBE[n % len(t.YOUTUBE)]
            if kind == PostType.INSTAGRAM:
                data["source_url"] = "https://www.instagram.com/p/mfano/"
            if kind == PostType.BREAKING:
                data["breaking_until"] = now + timedelta(hours=2)
            if n % 60 == 17:
                data |= {"is_sensitive": True, "content_warning": "Baadhi ya picha zinaweza kuhuzunisha"}
            services.save(actor=author, post_id=post.pk, version=post.version, data=data)
            services.release_lock(actor=author, post_id=post.pk)
            at -= timedelta(minutes=self.rng.randint(6, 75))
            self._finish(post, n, author, at, now)
            if n % 50 == 49:
                self.stdout.write(f"post {n + 1}/{total}")

    def _finish(self, post: Post, n: int, author: User, at: datetime, now: datetime) -> None:
        def go(actor: User, key: str, **kw: Any) -> None:
            post.refresh_from_db()
            services.transition(actor=actor, post_id=post.pk, key=key, version=post.version, **kw)

        # One in twenty is still on its way, so every list in the admin has something in it.
        stage = {3: "draft", 9: "submitted", 14: "in_review", 25: "scheduled", 33: "approved"}.get(n % 100)
        if post.type in (PostType.LIVE_BLOG, PostType.BREAKING) or stage is None:
            post.refresh_from_db()
            post.published_at = post.first_published_at = now if post.type == PostType.BREAKING else at
            if post.type == PostType.LIVE_BLOG and n % 2:
                post.live_ended_at = at + timedelta(hours=1)
            post.save()
            go(self.editor, "publish")
            return
        if stage == "draft":
            services.add_note(actor=self.editor, post_id=post.pk, text="Tafadhali ongeza chanzo cha pili.")
            return
        go(author, "submit")
        if stage == "in_review":
            go(self.editor, "start_review")
        elif stage in ("approved", "scheduled"):
            go(self.editor, "approve")
        if stage == "scheduled":
            go(self.editor, "schedule", scheduled_at=now + timedelta(hours=self.rng.randint(2, 60)))

    # ---- bodies ------------------------------------------------------------
    def _body(self, kind: str, i: int, slug: str, n: int) -> dict[str, Any]:
        count = 0

        def ident() -> str:
            nonlocal count
            count += 1
            return f"demo-{n}-{count:03d}"

        def text(value: str, *marks: str) -> dict[str, Any]:
            node: dict[str, Any] = {"type": "text", "text": value}
            return {**node, "marks": [{"type": m} for m in marks]} if marks else node

        def paragraph(value: str) -> dict[str, Any]:
            first, _, rest = value.partition(" ")
            content = [text(first, "bold"), text(f" {rest}")] if count == 0 and rest else [text(value)]
            return {"type": "paragraph", "id": ident(), "content": content}

        def figure() -> dict[str, Any]:
            asset = self._picture(slug)
            alt = asset.alt_en if i else asset.alt_sw
            caption = [text(("Hali ilivyo katika eneo hilo.", "The scene in the area.")[i])]
            return {"type": "image", "id": ident(), "asset": str(asset.pk), "alt": alt, "caption": caption}

        if kind == PostType.LIVE_BLOG:
            blocks = []
            for k, line in enumerate(t.LIVE * 2):
                inner: list[dict[str, Any]] = [paragraph(line[i])]
                if k == 3:
                    inner.append(figure())
                at = (timezone.now() - timedelta(minutes=11 * k)).isoformat(timespec="seconds")
                blocks.append({"type": "live_update", "id": ident(), "time": at, "blocks": inner})
            return {"version": 1, "blocks": blocks}
        paragraphs = [p[i] for p in self.rng.sample(t.PARAGRAPHS, k=self.rng.randint(4, 8))]
        if kind in (PostType.SHORT, PostType.VIDEO, PostType.YOUTUBE, PostType.INSTAGRAM):
            paragraphs = paragraphs[:2]
        extras: list[Callable[[], dict[str, Any]]] = []
        if kind == PostType.GALLERY:
            everything = [a for rows in self.pictures.values() for a in rows]
            chosen = self.rng.sample(everything, k=min(len(everything), self.rng.randint(6, 14)))
            items = [
                {"asset": str(a.pk), "alt": a.alt_en if i else a.alt_sw, "credit": CREDIT} for a in chosen
            ]
            extras.append(lambda: {"type": "gallery", "id": ident(), "items": items, "layout": "carousel"})
        elif len(paragraphs) > 3:
            quote, person = self.rng.choice(t.QUOTES)[i], self.rng.choice(t.PEOPLE)
            facts = [{"content": [text(f[i])]} for f in t.FACTS]
            extras = [
                figure,
                lambda: {
                    "type": "heading",
                    "id": ident(),
                    "level": 2,
                    "content": [text(("Kilichobadilika", "What changed")[i])],
                },
                lambda: {"type": "pull_quote", "id": ident(), "text": quote, "attribution": person},
                lambda: {
                    "type": "factbox",
                    "id": ident(),
                    "title": ("Kwa ufupi", "At a glance")[i],
                    "items": facts,
                },
            ]
        blocks = []
        for k, value in enumerate(paragraphs):
            blocks.append(paragraph(value))
            if k < len(extras):
                blocks.append(extras[k]())
        return {"version": 1, "blocks": blocks}


def film(picture: bytes, vertical: bool, seconds: int) -> bytes:
    """A slow push into a drawn picture, with two soft tones: motion and sound to test a player with."""
    size = "720x1280" if vertical else "1280x720"
    with tempfile.TemporaryDirectory() as tmp:
        source, out = Path(tmp) / "a.jpg", Path(tmp) / "a.mp4"
        source.write_bytes(picture)
        tone = 196 + zlib.crc32(picture) % 120
        zoom = f"zoompan=z='1+0.0011*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={seconds * 25}:s={size}:fps=25"
        done = subprocess.run(  # noqa: S603 (fixed arguments, no shell)
            ["ffmpeg", "-v", "error", "-y", "-i", str(source), "-f", "lavfi", "-i",  # noqa: S607
             f"aevalsrc='0.05*sin({tone}*2*PI*t)+0.04*sin({tone * 1.5}*2*PI*t)':d={seconds}", "-vf", zoom,
             "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-c:a", "aac", "-shortest", str(out)],
            capture_output=True, check=False, timeout=180,
        )  # fmt: skip
        if done.returncode:
            raise CommandError(done.stderr.decode()[-400:])
        return out.read_bytes()
