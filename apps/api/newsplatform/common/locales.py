from django.db import models


class Locale(models.TextChoices):
    SW = "sw"
    EN = "en"


DEFAULT = Locale.SW
