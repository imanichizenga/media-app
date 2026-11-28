"""Only bootstrap values come from the environment; everything else lives in the database (ADR-0011)."""

from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

from newsplatform.common import logging as platform_logging
from newsplatform.common.env import env_bool, env_int, env_list, env_str

BASE_DIR = Path(__file__).resolve().parents[2]
ENVIRONMENT = env_str("ENVIRONMENT", "dev")  # dev | test | staging | prod
IS_DEPLOYED = ENVIRONMENT in {"staging", "prod"}
# Which API this process serves. The public deployment does not contain admin routes at all (ADR-0003).
API_SURFACE = env_str("API_SURFACE", "public")
SECRET_KEY = env_str("DJANGO_SECRET_KEY", None if IS_DEPLOYED else "insecure-local-key-" + "x" * 48)
DEBUG = False
ALLOWED_HOSTS = env_list("ALLOWED_HOSTS", "localhost,127.0.0.1")
ROOT_URLCONF = f"config.urls_{API_SURFACE}"
ASGI_APPLICATION = "config.asgi.application"
TRUSTED_PROXY_HOPS = env_int("TRUSTED_PROXY_HOPS", 0)
ORIGIN_VERIFY_SECRET = env_str("ORIGIN_VERIFY_SECRET", "")

INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.auth",
    "django.contrib.postgres",
    "rest_framework",
    "drf_spectacular",
    "newsplatform.accounts",
    "newsplatform.rbac",
    "newsplatform.audit",
    "newsplatform.site_config",
    "newsplatform.approvals",
    "newsplatform.integrations",
    "newsplatform.staff_security",
    "newsplatform.realtime",
    "newsplatform.ops",
    "newsplatform.taxonomy",
    "newsplatform.media",
    "newsplatform.content",
    "newsplatform.seo",
    "newsplatform.pages",
    "newsplatform.engagement",
    "newsplatform.search",
    "newsplatform.notifications",
    "newsplatform.subscriptions",
]
MIDDLEWARE = [
    "newsplatform.common.middleware.RequestContextMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "newsplatform.common.middleware.SecurityHeadersMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "django.middleware.http.ConditionalGetMiddleware",
]
if API_SURFACE == "admin":
    MIDDLEWARE.append("newsplatform.staff_security.middleware.IpAllowlistMiddleware")


def database(url: str) -> dict[str, Any]:
    u = urlparse(url)
    return {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": u.path.lstrip("/"),
        "USER": unquote(u.username or ""),
        "PASSWORD": unquote(u.password or ""),
        "HOST": u.hostname or "",
        "PORT": str(u.port or 5432),
        # PgBouncer transaction pooling: no session state, no server-side cursors or prepared statements.
        "CONN_MAX_AGE": 0,
        "DISABLE_SERVER_SIDE_CURSORS": True,
        "OPTIONS": {
            "connect_timeout": 5,
            "prepare_threshold": None,
            "sslmode": env_str("DATABASE_SSLMODE", "require" if IS_DEPLOYED else "prefer"),
        },
    }


DATABASES = {
    "default": database(
        env_str(
            "DATABASE_URL",
            None if IS_DEPLOYED else "postgresql://news_owner:local-dev-only@127.0.0.1:5432/news",
        )
    )
}
if replica := env_str("DATABASE_REPLICA_URL", ""):
    DATABASES["replica"] = database(replica)
DATABASE_ROUTERS = ["newsplatform.common.db_router.ReplicaRouter"]
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REDIS_URL = env_str("REDIS_URL", None if IS_DEPLOYED else "redis://127.0.0.1:6379/0")
REDIS_CLUSTER = env_bool("REDIS_CLUSTER")
BROKER_URL = env_str("BROKER_URL", None if IS_DEPLOYED else "redis://127.0.0.1:6379/1")

# Pub/sub on the non-cluster group: signals are ephemeral, so nothing is stored (ADR-0020).
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.pubsub.RedisPubSubChannelLayer",
        "CONFIG": {"hosts": [BROKER_URL], "prefix": f"rt:{ENVIRONMENT}"},
    }
}

AUTH_USER_MODEL = "accounts.User"
PASSWORD_HASHERS = ["django.contrib.auth.hashers.Argon2PasswordHasher"]
AUTHENTICATION_BACKENDS: list[str] = []  # Authentication is explicit, in staff_security.services.

# Envelope encryption: KMS in AWS, an explicit local key elsewhere (ADR-0009).
KMS_KEY_ARN = env_str("KMS_KEY_ARN", None if IS_DEPLOYED else "")
LOCAL_ENCRYPTION_KEY = env_str("LOCAL_ENCRYPTION_KEY", "" if IS_DEPLOYED else "local-dev-encryption-key")
AWS_REGION = env_str("AWS_REGION", "af-south-1")
# Test seam for emulators; refused in deployed environments by a system check.
AWS_ENDPOINT_URL = env_str("AWS_ENDPOINT_URL", "")

# Local stand-ins for the media pipeline (ADR-0022). Each is refused in deployed environments.
STORAGE_ENDPOINT_URL = env_str("STORAGE_ENDPOINT_URL", "")  # SeaweedFS
LOCAL_TRANSCODER = env_bool("LOCAL_TRANSCODER")  # FFmpeg in place of MediaConvert
LOCAL_SCANNER = env_str("LOCAL_SCANNER", "")  # "clamav://host:port" or "eicar"
# Sign-in codes go to the log and back in the answer instead of by SMS (ADR-0050). Refused in deployed
# environments.
LOCAL_SMS = env_bool("LOCAL_SMS")
# Subscriptions without Snippe: a payment completes by itself a moment later (ADR-0052). Refused in deployed
# environments.
LOCAL_PAYMENTS = env_bool("LOCAL_PAYMENTS")
# Web Push (ADR-0051): who push services may write to about this site's notifications (mailto: or https:).
WEB_PUSH_SUBJECT = env_str("WEB_PUSH_SUBJECT", "" if IS_DEPLOYED else "mailto:newsroom@localhost")
LOCAL_WEB_ORIGIN = env_str(
    "LOCAL_WEB_ORIGIN", ""
)  # a website on this machine, told like the real one (ADR-0046)

# Staff realm
ADMIN_ORIGIN = env_str("ADMIN_ORIGIN", None if IS_DEPLOYED else "http://localhost:3001")
STAFF_COOKIE_SECURE = env_bool("STAFF_COOKIE_SECURE", True)
STAFF_COOKIE_NAME = "__Host-staff_session" if STAFF_COOKIE_SECURE else "staff_session"
WEBAUTHN_RP_ID = env_str("WEBAUTHN_RP_ID", None if IS_DEPLOYED else "localhost")

# Transport hardening
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https") if IS_DEPLOYED else None
SECURE_SSL_REDIRECT = IS_DEPLOYED
SECURE_REDIRECT_EXEMPT = [r"^health/"]
SECURE_HSTS_SECONDS = 63072000 if IS_DEPLOYED else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = SECURE_HSTS_PRELOAD = IS_DEPLOYED
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "no-referrer"
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
X_FRAME_OPTIONS = "DENY"
DATA_UPLOAD_MAX_MEMORY_SIZE = 1_048_576

LANGUAGE_CODE = "sw"
LANGUAGES = [("sw", "Kiswahili"), ("en", "English")]
TIME_ZONE = "Africa/Dar_es_Salaam"
USE_TZ = True
USE_I18N = True

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        ["newsplatform.staff_security.authentication.StaffSessionAuthentication"]
        if API_SURFACE == "admin"
        else []
    ),
    "DEFAULT_PERMISSION_CLASSES": ["newsplatform.rbac.permissions.DenyAll"],
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PARSER_CLASSES": ["rest_framework.parsers.JSONParser"],
    "DEFAULT_PAGINATION_CLASS": "newsplatform.common.pagination.TimeCursorPagination",
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "EXCEPTION_HANDLER": "newsplatform.common.errors.exception_handler",
    "UNAUTHENTICATED_USER": None,
    "DEFAULT_THROTTLE_CLASSES": [],
}
SPECTACULAR_SETTINGS = {
    "TITLE": f"News Platform {API_SURFACE} API",
    "VERSION": "1.0.0",
    "OAS_VERSION": "3.1.1",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
    "SORT_OPERATIONS": True,
    "SCHEMA_PATH_PREFIX": r"/api/v1",
    "POSTPROCESSING_HOOKS": [
        "drf_spectacular.hooks.postprocess_schema_enums",
        "newsplatform.common.schema.relax_nullable_json",
    ],
    "ENUM_NAME_OVERRIDES": {
        "PaymentMethodEnum": "newsplatform.subscriptions.models.Method",
        "PaymentStatusEnum": "newsplatform.subscriptions.models.PaymentStatus",
        "PlanIntervalEnum": "newsplatform.subscriptions.models.Interval",
        "PageKeyEnum": "newsplatform.pages.models.PageKey",
        "ThemeKeyEnum": "newsplatform.site_config.theme.derive.CHOICES",
        "LogoKindEnum": "newsplatform.site_config.models.BrandLogo.Kind",
        "IntegrationStatusEnum": "newsplatform.integrations.models.ConfigStatus",
        "TestRunStatusEnum": "newsplatform.integrations.models.RunStatus",
        "ApprovalStatusEnum": "newsplatform.approvals.models.ApprovalStatus",
        "StepStatusEnum": "newsplatform.integrations.base.STEP_STATUSES",
        "IntegrationSummaryStatusEnum": "newsplatform.integrations.models.SUMMARY_STATUSES",
        "PostStatusEnum": "newsplatform.content.models.Status",
        "PostTypeEnum": "newsplatform.content.models.PostType",
        "AssetStatusEnum": "newsplatform.media.models.AssetStatus",
        "AssetKindEnum": "newsplatform.media.models.Kind",
        "TransitionEnum": "newsplatform.content.workflow.KEYS",
        "BulkActionEnum": "newsplatform.content.services.BULK_CHOICES",
        "VisibilityEnum": "newsplatform.taxonomy.models.Visibility",
        "LocaleEnum": "newsplatform.common.locales.Locale",
        "CommentModeEnum": "newsplatform.engagement.policy.COMMENT_MODES",
        "SessionStageEnum": "newsplatform.staff_security.models.SessionStage",
    },
}

CELERY_BROKER_URL = BROKER_URL
CELERY_TASK_DEFAULT_QUEUE = "default"
CELERY_TASK_QUEUES = {
    name: {"exchange": name, "routing_key": name}
    for name in ("critical", "media", "notifications", "analytics", "sync", "default", "ops")
}
CELERY_TASK_ROUTES = {
    "newsplatform.ops.tasks.*": {"queue": "ops"},
    "newsplatform.integrations.tasks.*": {"queue": "default"},
    "newsplatform.staff_security.tasks.*": {"queue": "critical"},
    "newsplatform.content.tasks.publish_due": {"queue": "critical"},
    "newsplatform.content.tasks.announce": {"queue": "critical"},
    "newsplatform.content.tasks.*": {"queue": "default"},
    "newsplatform.media.tasks.*": {"queue": "media"},
}
CELERY_TASK_IGNORE_RESULT = True
CELERY_TASK_ACKS_LATE = True
CELERY_TASK_REJECT_ON_WORKER_LOST = True
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
CELERY_TASK_TIME_LIMIT = 300
CELERY_TASK_SOFT_TIME_LIMIT = 270
CELERY_TASK_SERIALIZER = "json"
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TIMEZONE = TIME_ZONE
CELERY_WORKER_HIJACK_ROOT_LOGGER = False
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True
# CloudWatch namespace for our own metrics. Empty outside AWS: nothing is sent.
METRICS_NAMESPACE = env_str("METRICS_NAMESPACE", None if IS_DEPLOYED else "")
CELERY_BEAT_SCHEDULE: dict[str, Any] = {
    "queue-depths": {
        "task": "newsplatform.ops.tasks.publish_queue_depths",
        "schedule": 60,
        "options": {"expires": 50},  # a late measurement is worse than none
    },
    "publish-due": {
        "task": "newsplatform.content.tasks.publish_due",
        "schedule": 60,
        "options": {"expires": 55},
    },
    "media-prune": {"task": "newsplatform.media.tasks.prune", "schedule": 6 * 3600},
    "audit-verify": {"task": "newsplatform.audit.tasks.verify_chain_task", "schedule": 6 * 3600},
    "audit-anchor": {"task": "newsplatform.audit.tasks.anchor_chain_task", "schedule": 24 * 3600},
    "approvals-expire": {"task": "newsplatform.approvals.tasks.expire_requests", "schedule": 900},
    "sessions-prune": {"task": "newsplatform.staff_security.tasks.prune", "schedule": 3600},
    "waf-sync": {"task": "newsplatform.staff_security.tasks.sync_waf_allowlist", "schedule": 3600},
}

# Search (ADR-0049). Required where deployed; empty locally, where Postgres is the engine.
OPENSEARCH_URL = env_str("OPENSEARCH_URL", None if IS_DEPLOYED else "")
OPENSEARCH_SIGV4 = env_bool("OPENSEARCH_SIGV4", IS_DEPLOYED)  # IAM-signed requests to the AWS domain
OPENSEARCH_PREFIX = env_str("OPENSEARCH_PREFIX", "news")
OPENSEARCH_SHARDS = env_int("OPENSEARCH_SHARDS", 2 if IS_DEPLOYED else 1)
OPENSEARCH_REPLICAS = env_int("OPENSEARCH_REPLICAS", 1 if IS_DEPLOYED else 0)
CELERY_TASK_ROUTES["newsplatform.search.tasks.*"] = {"queue": "default"}
CELERY_BEAT_SCHEDULE["readers-erase"] = {
    "task": "newsplatform.accounts.tasks.erase_due_readers",
    "schedule": 86400,
}
CELERY_BEAT_SCHEDULE["engagement-views"] = {
    "task": "newsplatform.engagement.tasks.persist_views",
    "schedule": 300,
}
CELERY_BEAT_SCHEDULE["engagement-reconcile"] = {
    "task": "newsplatform.engagement.tasks.reconcile_counts",
    "schedule": 3600,
}
CELERY_BEAT_SCHEDULE["search-reconcile"] = {
    "task": "newsplatform.search.tasks.reconcile",
    "schedule": 3600,
    "options": {"expires": 3000},
}

LOGGING_CONFIG = None
platform_logging.configure(env_str("LOG_LEVEL", "INFO"), json=IS_DEPLOYED)
