"""The newsroom's side of subscriptions (ADR-0052): the plans it sells, and what was paid."""

from datetime import timedelta
from typing import Any, ClassVar
from uuid import UUID

from django.db import transaction
from django.db.models import Count, Q, Sum
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers as S
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.audit.services import record
from newsplatform.common.api import StaffView
from newsplatform.common.errors import Conflict, NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.staff_security.authentication import session_of
from newsplatform.subscriptions.models import Interval, Method, Payment, PaymentStatus, Plan, Subscription

_VIEW = "settings.view"
_MANAGE = "settings.manage"
TONES = ["brand", "ember", "ocean", "forest", "violet", "night"]


class PlanAdminSerializer(S.ModelSerializer[Plan]):
    tone = S.ChoiceField(choices=TONES, required=False)
    features_sw = S.ListField(child=S.CharField(max_length=80), max_length=10, required=False)
    features_en = S.ListField(child=S.CharField(max_length=80), max_length=10, required=False)
    subscribers = S.IntegerField(read_only=True, default=0)

    class Meta:
        model = Plan
        fields = [
            "id",
            "code",
            "interval",
            "price",
            "currency",
            "name_sw",
            "name_en",
            "tagline_sw",
            "tagline_en",
            "features_sw",
            "features_en",
            "badge_sw",
            "badge_en",
            "tone",
            "highlighted",
            "is_active",
            "position",
            "subscribers",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "currency", "subscribers", "created_at", "updated_at"]

    def validate_price(self, value: int) -> int:
        if value < 500:
            raise S.ValidationError("At least 500 TZS: Snippe takes nothing smaller.")
        return value


class PaymentAdminSerializer(S.Serializer[Any]):
    id = S.UUIDField()
    created_at = S.DateTimeField()
    reader = S.CharField(help_text="The reader's name")
    plan = S.CharField()
    method = S.ChoiceField(choices=Method.choices)
    amount = S.IntegerField()
    currency = S.CharField()
    phone = S.CharField(allow_blank=True, help_text="All but the last three digits hidden")
    status = S.ChoiceField(choices=PaymentStatus.choices)
    channel = S.CharField(allow_blank=True)
    reference = S.CharField(allow_blank=True)


class SubscriptionSummarySerializer(S.Serializer[Any]):
    subscribers = S.IntegerField(help_text="Readers with paid time left")
    monthly = S.IntegerField()
    yearly = S.IntegerField()
    revenue_30d = S.IntegerField(help_text="Completed payments in the last 30 days, TZS")
    pending = S.IntegerField()


def _plans() -> Any:
    now = timezone.now()
    return Plan.objects.annotate(
        subscribers=Count("subscriptions__reader", filter=Q(subscriptions__ends_at__gt=now), distinct=True)
    ).order_by("interval", "position", "price")


def _announce() -> None:
    from newsplatform.content.tasks import announce

    # The plans page and every paywall's "from" price.
    transaction.on_commit(lambda: announce.delay(["plans", "premium"], []), robust=True)


def _masked(phone: str) -> str:
    return f"{phone[:4]}•••••{phone[-3:]}" if len(phone) > 7 else ""


class PlanListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _VIEW, "POST": _MANAGE}

    @extend_schema(operation_id="plans_list", responses=PlanAdminSerializer(many=True))
    def get(self, request: Request) -> Response:
        return Response(PlanAdminSerializer(_plans(), many=True).data)

    @extend_schema(
        operation_id="plans_create", request=PlanAdminSerializer, responses={201: PlanAdminSerializer}
    )
    @transaction.atomic
    def post(self, request: Request) -> Response:
        data = PlanAdminSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        if Plan.objects.filter(code=data.validated_data["code"]).exists():
            raise Conflict("A plan has this code already.", code="code_taken", field="code")
        plan = data.save()
        record(actor=session_of(request).user, action="plan.created", target=plan, after=data.data)
        _announce()
        return Response(PlanAdminSerializer(_plans().get(pk=plan.pk)).data, status=201)


class PlanView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"PUT": _MANAGE, "DELETE": _MANAGE}

    @staticmethod
    def _plan(plan_id: UUID) -> Plan:
        plan = Plan.objects.filter(pk=plan_id).first()
        if plan is None:
            raise NotFound("Not found")
        return plan

    @extend_schema(operation_id="plans_save", request=PlanAdminSerializer, responses=PlanAdminSerializer)
    @transaction.atomic
    def put(self, request: Request, plan_id: UUID) -> Response:
        plan = self._plan(plan_id)
        before = PlanAdminSerializer(plan).data
        data = PlanAdminSerializer(plan, data=request.data)
        data.is_valid(raise_exception=True)
        if Plan.objects.filter(code=data.validated_data["code"]).exclude(pk=plan.pk).exists():
            raise Conflict("A plan has this code already.", code="code_taken", field="code")
        data.save()
        record(
            actor=session_of(request).user, action="plan.updated", target=plan, before=before, after=data.data
        )
        return Response(PlanAdminSerializer(_plans().get(pk=plan.pk)).data)

    @extend_schema(operation_id="plans_delete", responses={204: None})
    @transaction.atomic
    def delete(self, request: Request, plan_id: UUID) -> Response:
        plan = self._plan(plan_id)
        # A plan someone paid for stays, hidden: its payments point at it.
        if plan.payments.exists():
            plan.is_active = False
            plan.save(update_fields=["is_active", "updated_at"])
        else:
            plan.delete()
        record(actor=session_of(request).user, action="plan.removed", label=plan.code)
        _announce()
        return Response(status=204)


class PaymentListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _VIEW}

    @extend_schema(
        operation_id="payments_list",
        parameters=[OpenApiParameter("status", str), OpenApiParameter("cursor", str)],
        responses=page_of(PaymentAdminSerializer),
    )
    def get(self, request: Request) -> Response:
        rows = Payment.objects.select_related("reader", "plan")
        if (state := request.query_params.get("status", "")) in PaymentStatus.values:
            rows = rows.filter(status=state)
        pages = TimeCursorPagination()
        page = pages.paginate_queryset(rows, request, view=self)
        body = [
            {
                "id": p.pk,
                "created_at": p.created_at,
                "reader": p.reader.display_name or p.reader.username or "",
                "plan": p.plan.name_en,
                "method": p.method,
                "amount": p.amount,
                "currency": p.currency,
                "phone": _masked(p.phone),
                "status": p.status,
                "channel": p.channel,
                "reference": p.reference,
            }
            for p in page or []
        ]
        return pages.get_paginated_response(PaymentAdminSerializer(body, many=True).data)


class SummaryView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _VIEW}

    @extend_schema(operation_id="subscriptions_summary", responses=SubscriptionSummarySerializer)
    def get(self, request: Request) -> Response:
        now = timezone.now()
        live = Subscription.objects.filter(ends_at__gt=now, starts_at__lte=now)
        paid = Payment.objects.filter(
            status=PaymentStatus.COMPLETED, completed_at__gt=now - timedelta(days=30)
        )
        return Response(
            {
                "subscribers": live.values("reader").distinct().count(),
                "monthly": live.filter(plan__interval=Interval.MONTH).values("reader").distinct().count(),
                "yearly": live.filter(plan__interval=Interval.YEAR).values("reader").distinct().count(),
                "revenue_30d": paid.aggregate(n=Sum("amount"))["n"] or 0,
                "pending": Payment.objects.filter(status=PaymentStatus.PENDING).count(),
            }
        )
