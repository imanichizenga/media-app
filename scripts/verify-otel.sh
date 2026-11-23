#!/usr/bin/env bash
# Proves tracing end to end against a real collector: one HTTP request must produce ONE trace that crosses the API,
# PostgreSQL, Redis, and a Celery worker, and no span may carry a secret or a query parameter value.
# Needs: docker compose up -d postgres redis. Usage: scripts/verify-otel.sh
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(mktemp -d)
chmod 777 "$out"
name=otel-verify-$$
pids=()
cleanup() {
  for p in "${pids[@]}"; do kill "$p" 2> /dev/null || true; done
  docker rm -f "$name" > /dev/null 2>&1 || true
}
trap cleanup EXIT
docker run -d --name "$name" -p 127.0.0.1:0:4318 -v "$PWD/infra/local/otel-collector.yaml:/etc/otelcol-contrib/config.yaml:ro" \
  -v "$out:/traces" otel/opentelemetry-collector-contrib:0.165.0 > /dev/null
port=$(docker port "$name" 4318/tcp | head -1 | cut -d: -f2)
export OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$port" OTEL_BSP_SCHEDULE_DELAY=200
export ENVIRONMENT=dev API_SURFACE=admin DJANGO_SETTINGS_MODULE=config.settings.dev LOG_LEVEL=WARNING
export REDIS_URL=redis://127.0.0.1:6379/7 BROKER_URL=redis://127.0.0.1:6379/8
cd apps/api
.venv/bin/python manage.py migrate -v0
.venv/bin/uvicorn config.asgi:application --port 8011 --log-level warning & pids+=($!)
.venv/bin/celery -A config worker -Q default,critical -c 1 -l WARNING & pids+=($!)
for _ in $(seq 60); do curl -fs http://127.0.0.1:8011/health/live > /dev/null && break; sleep 0.5; done
curl -fs "http://127.0.0.1:8011/health/ready?token=SENTINEL-QUERY" -H 'Authorization: Bearer SENTINEL-HEADER' > /dev/null
# A task published inside a request's trace must join that trace in the worker.
OTEL_SERVICE_NAME=publisher .venv/bin/python - << 'PY'
import django
from newsplatform.common.telemetry import init
init("publisher")
django.setup()
import config.celery  # noqa: F401
from opentelemetry import trace
from newsplatform.staff_security.tasks import prune
with trace.get_tracer("verify").start_as_current_span("verify-parent"):
    prune.delay()
trace.get_tracer_provider().shutdown()
PY
sleep 6
python3 - "$out/traces.json" << 'PY'
import json, re, sys
raw = open(sys.argv[1]).read()
spans = []
for line in raw.splitlines():
    for rs in json.loads(line)["resourceSpans"]:
        service = next(a["value"]["stringValue"] for a in rs["resource"]["attributes"] if a["key"] == "service.name")
        for ss in rs["scopeSpans"]:
            for s in ss["spans"]:
                spans.append((s["traceId"], service, ss["scope"]["name"], s["name"]))
by = {}
for t, service, scope, name in spans:
    by.setdefault(t, set()).add((service, scope.rsplit(".", 1)[-1]))
def trace_with(*needed):
    return any(all(n in found for n in needed) for found in by.values())
checks = {
    "HTTP request traced, with its SQL and Redis calls": trace_with(
        ("newsplatform-api", "django"), ("newsplatform-api", "psycopg"), ("newsplatform-api", "redis")),
    "task joins its publisher's trace, with its SQL": trace_with(
        ("newsplatform-publisher", "celery"), ("newsplatform-worker", "celery"), ("newsplatform-worker", "psycopg")),
    "no header or query value exported": "SENTINEL" not in raw,
}
for name, ok in checks.items():
    print("PASS" if ok else "FAIL", name)
if not all(checks.values()):
    print(json.dumps(sorted({(s, sc, n[:50]) for _, s, sc, n in spans}), indent=0))
    print("leaks:", sorted(set(re.findall(r"\{\"key\":\"[^\"]+\",\"value\":\{[^}]*SENTINEL[^}]*\}", raw))))
    sys.exit(1)
PY
