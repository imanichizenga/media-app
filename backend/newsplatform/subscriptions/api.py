"""Readers and subscriptions (ADR-0052): the plans, paying, and the whole of a story for subscribers."""

import re
from typing import Any
from uuid import UUID

from django.conf import settings
from django.http import HttpRequest, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers as S
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.accounts.reader_api import ReaderView, body, private, reader
from newsplatform.common.locales import DEFAULT, Locale
from newsplatform.common.ratelimit import Limit
from newsplatform.content.public_shapes import ArticleSerializer
from newsplatform.subscriptions import services
from newsplatform.subscriptions.models import Interval, Method, PaymentStatus

_LOCALE = OpenApiParameter("locale", str, enum=list(Locale.values), required=False)
_PATH = re.compile(r"^/(?!/)[A-Za-z0-9/_.~%=&?-]{0,300}$")


def _locale(request: Request) -> str:
    value = str(request.query_params.get("locale", DEFAULT))
    return value if value in Locale.values else DEFAULT


class PlanSerializer(S.Serializer[Any]):
    id = S.UUIDField()
    code = S.CharField()
    interval = S.ChoiceField(choices=Interval.choices)
    price = S.IntegerField(help_text="Whole shillings")
    currency = S.CharField()
    name = S.CharField()
    tagline = S.CharField(allow_blank=True)
    features = S.ListField(child=S.CharField())
    badge = S.CharField(allow_blank=True, help_text="A word on the card's top; empty for none")
    tone = S.CharField(help_text="brand, ember, ocean, forest, violet or night")
    highlighted = S.BooleanField()
    monthly_equivalent = S.IntegerField(
        help_text="A year's price over twelve; the month's own price otherwise"
    )


class OfferSerializer(S.Serializer[Any]):
    enabled = S.BooleanField()
    preview_paragraphs = S.IntegerField()
    methods = S.ListField(child=S.ChoiceField(choices=Method.choices))
    plans = PlanSerializer(many=True)


class MySubscriptionSerializer(S.Serializer[Any]):
    active = S.BooleanField()
    plan = PlanSerializer(allow_null=True)
    ends_at = S.DateTimeField(allow_null=True)


class CheckoutSerializer(S.Serializer[Any]):
    plan = S.UUIDField()
    method = S.ChoiceField(choices=Method.choices)
    phone = S.CharField(required=False, allow_blank=True, max_length=20)
    return_path = S.CharField(
        required=False,
        allow_blank=True,
        max_length=300,
        help_text="Where a card checkout comes back to, on the site",
    )


class PaymentSerializer(S.Serializer[Any]):
    id = S.UUIDField()
    status = S.ChoiceField(choices=PaymentStatus.choices)
    method = S.ChoiceField(choices=Method.choices)
    amount = S.IntegerField()
    currency = S.CharField()
    plan = S.CharField()
    checkout_url = S.CharField(allow_blank=True, help_text="Cards: send the reader here")
    completed_at = S.DateTimeField(allow_null=True)
    subscription = MySubscriptionSerializer()


def _site(path: str) -> str:
    if not path or not _PATH.match(path):
        return ""
    from newsplatform.integrations.providers.web import WebConfig
    from newsplatform.integrations.services import get_active

    web = get_active("web", WebConfig)
    origin = f"https://{web.host}" if web else settings.LOCAL_WEB_ORIGIN
    return f"{origin.rstrip('/')}{path}" if origin else ""


class OfferView(ReaderView):
    """What a reader may buy. The same for everyone."""

    needs_reader = False

    @extend_schema(operation_id="subscription_plans", parameters=[_LOCALE], responses=OfferSerializer)
    def get(self, request: Request) -> Response:
        return Response(services.offer(_locale(request)), headers={"Cache-Control": "public, max-age=60"})


class MineView(ReaderView):
    @extend_schema(operation_id="subscription_mine", parameters=[_LOCALE], responses=MySubscriptionSerializer)
    def get(self, request: Request) -> Response:
        return private(services.mine(reader(request), _locale(request)))


class CheckoutView(ReaderView):
    limit = Limit(10, 600)

    @extend_schema(
        operation_id="subscription_checkout", request=CheckoutSerializer, responses={201: PaymentSerializer}
    )
    def post(self, request: Request) -> Response:
        data = CheckoutSerializer(data=body(request))
        data.is_valid(raise_exception=True)
        v = data.validated_data
        who = reader(request)
        payment = services.start(
            reader=who,
            plan_id=str(v["plan"]),
            method=v["method"],
            phone=v.get("phone", ""),
            return_url=_site(v.get("return_path", "")),
        )
        return private({**services.payment_body(payment), "subscription": services.mine(who, DEFAULT)}, 201)


class PaymentView(ReaderView):
    """Where a payment is, for the reader watching it. Asks Snippe now and then, in case its word is late."""

    limit = Limit(120, 60)

    @extend_schema(operation_id="subscription_payment", parameters=[_LOCALE], responses=PaymentSerializer)
    def get(self, request: Request, payment_id: UUID) -> Response:
        who = reader(request)
        payment = services.check(services.get(who, payment_id))
        return private(
            {**services.payment_body(payment), "subscription": services.mine(who, _locale(request))}
        )


class FullStoryView(ReaderView):
    """The whole of a story for subscribers, for a reader with paid time left (402 otherwise)."""

    limit = Limit(240, 60)

    @extend_schema(operation_id="subscription_story", parameters=[_LOCALE], responses=ArticleSerializer)
    def get(self, request: Request, post_id: UUID) -> Response:
        return private(services.full(reader(request), post_id, _locale(request)))


@csrf_exempt
@require_POST
def webhook(request: HttpRequest) -> HttpResponse:
    """Snippe, telling of a payment (signed). Anything not signed by Snippe is refused without a word."""
    headers = {k: request.headers.get(k, "") for k in ("X-Webhook-Timestamp", "X-Webhook-Signature")}
    if len(request.body) > 64_000 or not services.webhook(request.body, headers):
        return HttpResponse(status=401)
    return HttpResponse(status=204)
