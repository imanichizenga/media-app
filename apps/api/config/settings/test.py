import os

os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("API_SURFACE", "admin")
os.environ.setdefault("LOG_LEVEL", "CRITICAL")
from config.settings.base import *  # noqa: F403

REDIS_URL = os.environ.get("TEST_REDIS_URL", "redis://127.0.0.1:6379/9")
CELERY_BROKER_URL = BROKER_URL = REDIS_URL  # base derives the first from its own value
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
STAFF_COOKIE_SECURE = True
