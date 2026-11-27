"""Readers who engage, for trying the site and the apps locally (ADR-0050). Refused in deployed environments.

Everyone here is made up: Swahili names, numbers in +255 700 000 0xx (a range no operator gives out), and
comments that say ordinary things about the stories. The first reader, +255 700 000 001, is yours to sign in
as with LOCAL_SMS: the code comes back on the screen.
"""

import random
from datetime import timedelta
from typing import Any

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from newsplatform.accounts.models import Consent, Identity, IdentityProvider, User
from newsplatform.content.models import Post, Status
from newsplatform.engagement import counters
from newsplatform.engagement.models import (
    Bookmark,
    Comment,
    CommentLike,
    CommentStatus,
    Follow,
    FollowKind,
    Like,
    PostStats,
    Reading,
)

NAMES = [
    "Asha Mwakyusa",
    "Juma Hamisi",
    "Neema Mollel",
    "Baraka Massawe",
    "Rehema Said",
    "Daudi Kimaro",
    "Zawadi Mushi",
    "Emmanuel Lyimo",
    "Fatuma Abdallah",
    "Godfrey Mrema",
    "Halima Omari",
    "Ibrahim Swai",
    "Joyce Minja",
    "Kassim Mfinanga",
    "Lucy Shirima",
    "Mussa Kombo",
    "Nuru Salim",
    "Omari Kiwelu",
    "Pendo Urassa",
    "Rashidi Mtei",
    "Saida Ngowi",
    "Tumaini Mallya",
    "Upendo Temba",
    "Victor Moshi",
    "Winfrida Laizer",
    "Yusuf Mbwana",
    "Zuhura Kitwana",
    "Amani Chacha",
    "Bahati Nyerere",
    "Consolata Mbise",
]
COMMENTS_SW = [
    "Habari nzuri sana, asanteni kwa kutujuza.",
    "Hii ni hatua kubwa kwa wananchi wa eneo hili.",
    "Natumaini serikali itafuatilia utekelezaji wake.",
    "Tunahitaji habari kama hizi mara kwa mara.",
    "Je, mradi huu utafika mikoa mingine pia?",
    "Pongezi kwa waliofanikisha jambo hili!",
    "Nimeisoma mara mbili, imeandikwa vizuri sana.",
    "Wakazi wanastahili kushirikishwa zaidi katika maamuzi.",
    "Hongera kwa mwandishi, maelezo yako wazi.",
    "Tusubiri tuone matokeo baada ya miezi michache.",
]
REPLIES_SW = [
    "Nakubaliana nawe kabisa.",
    "Kweli kabisa, ndiyo maana tunahitaji uwazi.",
    "Asante kwa mtazamo huu.",
    "Mimi naona tofauti kidogo, lakini hoja yako ina uzito.",
    "Ndiyo, hata kwetu tumeona mabadiliko.",
]


class Command(BaseCommand):
    help = "Made-up readers who like, save, follow and comment (local only)."

    def add_arguments(self, parser: Any) -> None:
        parser.add_argument("--readers", type=int, default=30)
        parser.add_argument("--stories", type=int, default=60)
        parser.add_argument("--seed", type=int, default=7)

    def handle(self, *args: Any, readers: int, stories: int, seed: int, **opts: Any) -> None:
        if settings.IS_DEPLOYED:
            raise CommandError("Made-up readers are for local machines only.")
        rng = random.Random(seed)  # noqa: S311 (made-up data, not security)
        posts = list(Post.objects.filter(status=Status.PUBLISHED).order_by("-published_at")[:stories])
        if not posts:
            raise CommandError("Publish some stories first (seed_demo).")
        from newsplatform.accounts.signin import rules

        terms = rules().terms_version
        made: list[User] = []
        with transaction.atomic():
            for i, name in enumerate(NAMES[:readers]):
                phone = f"+255700000{i + 1:03d}"
                user = User.objects.filter(phone=phone).first() or User.objects.create_user(
                    phone=phone,
                    display_name=name,
                    username=name.split()[0].lower() + f"{i + 1:02d}",
                )
                Identity.objects.get_or_create(
                    provider=IdentityProvider.PHONE, subject=phone, defaults={"user": user}
                )
                Consent.objects.get_or_create(user=user, kind="terms", version=terms)
                made.append(user)
            now = timezone.now()
            for post in posts:
                fans = rng.sample(made, k=rng.randint(2, len(made)))
                Like.objects.bulk_create([Like(user=u, post=post) for u in fans], ignore_conflicts=True)
                keepers = rng.sample(made, k=rng.randint(0, len(made) // 3))
                Bookmark.objects.bulk_create(
                    [Bookmark(user=u, post=post) for u in keepers], ignore_conflicts=True
                )
                if Comment.objects.filter(post=post).exists():
                    continue
                for n in range(rng.randint(0, 6)):
                    writer = rng.choice(made)
                    top = Comment.objects.create(
                        post=post,
                        user=writer,
                        body=rng.choice(COMMENTS_SW),
                        status=CommentStatus.VISIBLE,
                    )
                    Comment.objects.filter(pk=top.pk).update(
                        created_at=now - timedelta(minutes=rng.randint(5, 2000))
                    )
                    likers = rng.sample(made, k=rng.randint(0, 8))
                    CommentLike.objects.bulk_create(
                        [CommentLike(user=u, comment=top) for u in likers], ignore_conflicts=True
                    )
                    replies = rng.randint(0, 3) if n < 3 else 0
                    for _ in range(replies):
                        Comment.objects.create(
                            post=post, user=rng.choice(made), parent=top, body=rng.choice(REPLIES_SW)
                        )
                    Comment.objects.filter(pk=top.pk).update(like_count=len(likers), reply_count=replies)
            # Openings: everyone who liked a story read it, and many more guests did too.
            for post in posts:
                fan_ids = list(Like.objects.filter(post=post).values_list("user_id", flat=True))
                Reading.objects.bulk_create(
                    [
                        Reading(user_id=u, post=post, last_at=now - timedelta(minutes=rng.randint(1, 3000)))
                        for u in fan_ids
                    ],
                    ignore_conflicts=True,
                )
                people = len(fan_ids) + rng.randint(40, 4000)
                PostStats.objects.update_or_create(
                    post=post, defaults={"readers": people, "views": int(people * rng.uniform(1.2, 2.6))}
                )
            categories = {p.category_id for p in posts}
            for user in made:
                for cat in rng.sample(sorted(categories, key=str), k=min(3, len(categories))):
                    Follow.objects.get_or_create(user=user, kind=FollowKind.CATEGORY, target=cat)
        counters.reconcile([str(p.pk) for p in posts])
        self.stdout.write(
            self.style.SUCCESS(
                f"{len(made)} readers, {Like.objects.count()} likes, {Comment.objects.count()} comments. "
                "Sign in as +255 700 000 001 (LOCAL_SMS shows the code)."
            )
        )
