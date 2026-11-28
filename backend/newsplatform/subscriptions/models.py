"""Paid reading (ADR-0052): the plans the newsroom sells, what readers bought, and every payment for it."""

from django.conf import settings
from django.db import models
from django.db.models import Q

from newsplatform.common.models import BaseModel


class Interval(models.TextChoices):
    MONTH = "month"
    YEAR = "year"


class Plan(BaseModel):
    """One card on the plans page. Everything a reader sees on it is written here, in both languages."""

    code = models.SlugField(max_length=40, unique=True)
    interval = models.CharField(max_length=8, choices=Interval)
    price = models.PositiveIntegerField(help_text="In whole shillings (TZS), as Snippe takes it")
    currency = models.CharField(max_length=3, default="TZS")
    name_sw = models.CharField(max_length=60)
    name_en = models.CharField(max_length=60)
    tagline_sw = models.CharField(max_length=140, blank=True, default="")
    tagline_en = models.CharField(max_length=140, blank=True, default="")
    features_sw = models.JSONField(default=list)
    features_en = models.JSONField(default=list)
    # A word on the card's top ("Most popular", "Save 20%"): empty for none.
    badge_sw = models.CharField(max_length=30, blank=True, default="")
    badge_en = models.CharField(max_length=30, blank=True, default="")
    # The colour the card's top is drawn in, from the brand's red to a deep blue (support/packages/ui).
    tone = models.CharField(max_length=12, default="brand")
    highlighted = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    position = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["interval", "position", "price"]

    def __str__(self) -> str:
        return f"{self.code} {self.price} {self.currency}/{self.interval}"


class Subscription(BaseModel):
    """A reader's paid time. Each payment adds a period after whatever is left: never two at once."""

    reader = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions"
    )
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, related_name="subscriptions")
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    payment = models.OneToOneField("Payment", on_delete=models.PROTECT, related_name="subscription")

    class Meta:
        indexes = [models.Index(fields=["reader", "-ends_at"])]

    def __str__(self) -> str:
        return f"{self.reader_id} {self.plan_id} until {self.ends_at:%Y-%m-%d}"


class PaymentStatus(models.TextChoices):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    EXPIRED = "expired"
    VOIDED = "voided"


class Method(models.TextChoices):
    MOBILE = "mobile"
    CARD = "card"


class Payment(BaseModel):
    reader = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="payments")
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, related_name="payments")
    method = models.CharField(max_length=8, choices=Method)
    amount = models.PositiveIntegerField()
    currency = models.CharField(max_length=3)
    phone = models.CharField(max_length=16, blank=True, default="")
    status = models.CharField(max_length=10, choices=PaymentStatus, default=PaymentStatus.PENDING)
    # Snippe's own: the payment's reference, or the checkout session's, and where a card is paid.
    reference = models.CharField(max_length=80, blank=True, default="")
    checkout_url = models.URLField(max_length=500, blank=True, default="")
    channel = models.CharField(max_length=40, blank=True, default="")
    failure = models.CharField(max_length=200, blank=True, default="")
    completed_at = models.DateTimeField(null=True)
    checked_at = models.DateTimeField(null=True)

    class Meta:
        indexes = [
            models.Index(fields=["reader", "-created_at"]),
            models.Index(fields=["status", "-created_at"]),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=["reference"], condition=~Q(reference=""), name="payment_reference_once"
            )
        ]

    def __str__(self) -> str:
        return f"{self.method} {self.amount} {self.currency} {self.status}"


class WebhookEvent(models.Model):
    """Snippe may say a thing twice: an event is acted on once."""

    id = models.CharField(max_length=80, primary_key=True)
    kind = models.CharField(max_length=40)
    received_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return self.id
