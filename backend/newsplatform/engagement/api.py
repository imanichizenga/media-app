"""What readers do with stories (ADR-0050). Writes need a reader; comment lists are public and kept
briefly."""

import base64
import json
from datetime import datetime
from typing import Any

from django.db.models import Q
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.accounts import reader_shapes as shapes
from newsplatform.accounts.reader_api import PRIVATE, ReaderView, body, private, reader, reader_or_none
from newsplatform.common.errors import DomainError
from newsplatform.engagement import counters, services
from newsplatform.engagement.models import Bookmark, Comment, CommentLike, CommentStatus, Follow, Like

PAGE = 20


def _cursor(row: Comment) -> str:
    raw = json.dumps([row.created_at.isoformat(), str(row.pk)]).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _after(cursor: str) -> tuple[datetime, str] | None:
    if not cursor:
        return None
    try:
        at, pk = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
        return datetime.fromisoformat(at), str(pk)
    except ValueError, TypeError:
        return None


def _shape(row: Comment, *, me: Any, liked: set[str], writers: set[str]) -> dict[str, Any]:
    user = row.user
    return {
        "id": str(row.pk),
        "body": row.body,
        "created_at": row.created_at.isoformat(),
        "author": {
            "name": user.display_name or user.username or "",
            "username": user.username or "",
            "initial": (user.display_name or user.username or "?")[:1].upper(),
            # Readers see who wrote the story answering them (SPEC: author badge).
            "is_writer": str(user.pk) in writers,
        },
        "like_count": row.like_count,
        "reply_count": row.reply_count,
        "liked": str(row.pk) in liked,
        "mine": bool(me and me.is_authenticated and row.user_id == me.pk),
        "pinned": row.pinned,
        "held": row.status == CommentStatus.HELD,
        "parent": str(row.parent_id) if row.parent_id else None,
    }


class CommentsView(ReaderView):
    """GET: a page of comments (or one comment's replies). POST: a new one. Signed-in readers also see their
    own
    held comments and which they liked, so their answers are private; everyone else's may be kept 15 s."""

    needs_reader = False

    @extend_schema(
        operation_id="comments",
        parameters=[OpenApiParameter("cursor", str), OpenApiParameter("parent", str)],
        responses=shapes.CommentPageSerializer,
    )
    def get(self, request: Request, post_id: str) -> Response:
        post = services.post_of(post_id)
        me = reader_or_none(request)
        parent = request.query_params.get("parent") or None
        visible = Q(status=CommentStatus.VISIBLE) | (
            Q(status=CommentStatus.HELD, user=me) if me else Q(pk=None)
        )
        rows = Comment.objects.filter(visible, post=post).select_related("user")
        if parent:
            rows = rows.filter(parent__pk=parent).order_by("created_at", "pk")  # a conversation reads down
        else:
            rows = rows.filter(parent__isnull=True).order_by("-pinned", "-created_at", "-pk")
        after = _after(request.query_params.get("cursor", ""))
        if after:
            at, pk = after
            rows = (
                rows.filter(Q(created_at__gt=at) | Q(created_at=at, pk__gt=pk))
                if parent
                else rows.filter(Q(created_at__lt=at) | Q(created_at=at, pk__lt=pk))
            )
        page = list(rows[: PAGE + 1])
        more = len(page) > PAGE
        page = page[:PAGE]
        liked = (
            set(
                map(
                    str,
                    CommentLike.objects.filter(user=me, comment__in=page).values_list(
                        "comment_id", flat=True
                    ),
                )
            )
            if me
            else set()
        )
        writers = set(map(str, post.bylines.values_list("user_id", flat=True)))
        data = {
            "policy": services.policy_of(post).model_dump(mode="json"),
            "count": counters.get([str(post.pk)])[str(post.pk)]["comments"],
            "results": [_shape(r, me=me, liked=liked, writers=writers) for r in page],
            "next_cursor": _cursor(page[-1]) if more else None,
        }
        if me:
            return private(data)
        return Response(
            data, headers={"Cache-Control": "public, max-age=0, s-maxage=15", "Vary": "Authorization"}
        )

    @extend_schema(
        operation_id="comment_create",
        request=shapes.NewCommentSerializer,
        responses={201: shapes.CommentSerializer},
    )
    def post(self, request: Request, post_id: str) -> Response:
        row = services.comment(
            reader(request), post_id, str(body(request).get("body", "")), body(request).get("parent") or None
        )
        writers = set(map(str, row.post.bylines.values_list("user_id", flat=True)))
        return private(_shape(row, me=reader(request), liked=set(), writers=writers), 201)


class CommentView(ReaderView):
    @extend_schema(operation_id="comment_delete", request=None, responses={204: None})
    def delete(self, request: Request, comment_id: str) -> Response:
        services.delete_comment(reader(request), comment_id)
        return private(None, 204)


class CommentLikeView(ReaderView):
    @extend_schema(operation_id="comment_like", request=None, responses=shapes.CommentLikedSerializer)
    def put(self, request: Request, comment_id: str) -> Response:
        return private(
            {"liked": True, "like_count": services.like_comment(reader(request), comment_id, True)}
        )

    @extend_schema(operation_id="comment_unlike", request=None, responses=shapes.CommentLikedSerializer)
    def delete(self, request: Request, comment_id: str) -> Response:
        return private(
            {"liked": False, "like_count": services.like_comment(reader(request), comment_id, False)}
        )


class LikeView(ReaderView):
    @extend_schema(operation_id="like", request=None, responses=shapes.LikedSerializer)
    def put(self, request: Request, post_id: str) -> Response:
        return private(services.like(reader(request), post_id, True))

    @extend_schema(operation_id="unlike", request=None, responses=shapes.LikedSerializer)
    def delete(self, request: Request, post_id: str) -> Response:
        return private(services.like(reader(request), post_id, False))


class BookmarkView(ReaderView):
    @extend_schema(operation_id="bookmark", request=None, responses=shapes.BookmarkedSerializer)
    def put(self, request: Request, post_id: str) -> Response:
        return private(services.bookmark(reader(request), post_id, True))

    @extend_schema(operation_id="unbookmark", request=None, responses=shapes.BookmarkedSerializer)
    def delete(self, request: Request, post_id: str) -> Response:
        return private(services.bookmark(reader(request), post_id, False))


class StateView(ReaderView):
    """Counts and this reader's marks for up to 50 posts: `?posts=id,id`. Guests get the counts alone."""

    needs_reader = False

    @extend_schema(
        operation_id="engagement_state",
        parameters=[
            OpenApiParameter("posts", str, required=True, description="Comma-separated post ids, at most 50")
        ],
        responses={
            (200, "application/json"): {
                "type": "object",
                "additionalProperties": {"$ref": "#/components/schemas/PostState"},
            }
        },
    )
    def get(self, request: Request) -> Response:
        ids = [p for p in request.query_params.get("posts", "").split(",") if p]
        me = reader_or_none(request)
        data = services.state(me, ids)
        if me:
            return private(data)
        return Response(data, headers={"Cache-Control": "public, max-age=0, s-maxage=10"})


class FollowView(ReaderView):
    @extend_schema(operation_id="follow", request=None, responses=shapes.FollowingSerializer)
    def put(self, request: Request, kind: str, target: str) -> Response:
        return private({"following": services.follow(reader(request), kind, target, True)})

    @extend_schema(operation_id="unfollow", request=None, responses=shapes.FollowingSerializer)
    def delete(self, request: Request, kind: str, target: str) -> Response:
        return private({"following": services.follow(reader(request), kind, target, False)})


class MyListView(ReaderView):
    """The reader's saved and liked stories, newest first, as cards; and whom they follow."""

    @extend_schema(
        operation_id="my_list",
        parameters=[OpenApiParameter("locale", str)],
        responses=shapes.CardListSerializer,
        description="`what`: saved, liked (cards) or follows (FollowList).",
    )
    def get(self, request: Request, what: str) -> Response:
        from newsplatform.content.models import Publication
        from newsplatform.content.selectors import card

        locale = "en" if request.query_params.get("locale") == "en" else "sw"
        if what == "follows":
            follows = Follow.objects.filter(user=reader(request)).values("kind", "target")
            return private({"results": [{"kind": f["kind"], "target": str(f["target"])} for f in follows]})
        lists: dict[str, type[Bookmark] | type[Like]] = {"saved": Bookmark, "liked": Like}
        model = lists.get(what)
        if model is None:
            raise DomainError("Unknown list.", code="validation_error")
        ids = list(
            model.objects.filter(user=reader(request))
            .order_by("-created_at")
            .values_list("post_id", flat=True)[:200]
        )
        pubs = {
            p.post_id: p
            for p in Publication.objects.filter(post_id__in=ids, locale=locale).only(
                "card", "modified_at", "post_id"
            )
        }
        return Response(
            {"results": [card(pubs[i]) for i in ids if i in pubs]},
            headers=PRIVATE,
        )


class OpenedView(ReaderView):
    """A story was opened: counted (views, readers) and its counts given back. Guests too."""

    needs_reader = False

    @extend_schema(
        operation_id="opened", request=shapes.OpenedSerializer, responses=shapes.PostStateSerializer
    )
    def post(self, request: Request, post_id: str) -> Response:
        return private(
            services.opened(reader_or_none(request), post_id, str(body(request).get("device", "")))
        )


class ReadersView(ReaderView):
    """Who read the story: signed-in readers who did not choose to be left out, and how many guests."""

    needs_reader = False

    @extend_schema(
        operation_id="readers",
        parameters=[OpenApiParameter("cursor", str)],
        responses=shapes.ReadersSerializer,
    )
    def get(self, request: Request, post_id: str) -> Response:
        data = services.readers_of(post_id, request.query_params.get("cursor", ""))
        return Response(data, headers={"Cache-Control": "public, max-age=0, s-maxage=30"})
