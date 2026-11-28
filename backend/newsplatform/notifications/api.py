"""Web Push for readers' browsers: the site's public key, and subscribing (ADR-0051)."""

from typing import Any

from drf_spectacular.utils import extend_schema
from rest_framework import serializers as S
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.accounts.reader_api import ReaderView, body, private, reader_or_none
from newsplatform.common.locales import Locale
from newsplatform.common.ratelimit import Limit
from newsplatform.notifications import services


class PushKeySerializer(S.Serializer[Any]):
    enabled = S.BooleanField(help_text="The newsroom sends notifications of new stories.")
    public_key = S.CharField(help_text="VAPID application server key, base64url (applicationServerKey).")


class PushKeysSerializer(S.Serializer[Any]):
    p256dh = S.CharField()
    auth = S.CharField()


class PushSubscriptionSerializer(S.Serializer[Any]):
    endpoint = S.URLField()
    keys = PushKeysSerializer()
    locale = S.ChoiceField(choices=Locale.choices, required=False)


class PushEndpointSerializer(S.Serializer[Any]):
    endpoint = S.URLField()


class PushKeyView(ReaderView):
    needs_reader = False

    @extend_schema(operation_id="push_key", responses=PushKeySerializer)
    def get(self, request: Request) -> Response:
        on = services.enabled()
        return Response(
            {"enabled": on, "public_key": services.keys()[0] if on else ""},
            headers={"Cache-Control": "public, max-age=300"},
        )


class PushSubscriptionsView(ReaderView):
    """This browser wants to hear of new stories (or no longer does). Signed in or not."""

    needs_reader = False
    limit = Limit(20, 3600)

    @extend_schema(operation_id="push_subscribe", request=PushSubscriptionSerializer, responses={204: None})
    def post(self, request: Request) -> Response:
        services.subscribe(body(request), reader_or_none(request))
        return private(None, 204)

    @extend_schema(operation_id="push_unsubscribe", request=PushEndpointSerializer, responses={204: None})
    def delete(self, request: Request) -> Response:
        services.unsubscribe(str(body(request).get("endpoint", "")))
        return private(None, 204)
