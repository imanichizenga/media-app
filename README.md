# News platform

Backend (Django), admin console (Next.js), design tokens, API clients and AWS infrastructure. Status: [docs/PROGRESS.md](docs/PROGRESS.md).

## Run locally

Needs Docker, uv, Node 24, pnpm 12.

```sh
docker compose up -d --wait
cd apps/api && uv sync && export API_SURFACE=admin
uv run python manage.py migrate
uv run python manage.py bootstrap_super_admin you@example.com   # prints a one-time link
uv run uvicorn config.asgi:application --port 8001 &
uv run celery -A config worker -Q critical,default &
cd ../.. && pnpm install && pnpm --filter @news/design-tokens build
API_PROXY_TARGET=http://127.0.0.1:8001 pnpm --filter @news/admin dev   # http://localhost:3001
```

## Check

| What           | Command                                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| API            | `cd apps/api && uv run pytest --cov` · `uv run mypy newsplatform config` · `uv run ruff check .`        |
| Web            | `pnpm lint && pnpm typecheck && pnpm test`                                                              |
| End to end     | `API_PROXY_TARGET=http://127.0.0.1:8001 pnpm --filter @news/admin build && pnpm --filter @news/e2e e2e` |
| Infrastructure | `terraform -chdir=infra/terraform/modules/platform test`                                                |

After changing the API: `manage.py spectacular` (see CI), `pnpm --filter @news/api-client generate`, `scripts/generate-dart-client.sh`.

Decisions: [docs/adr](docs/adr/README.md) · Security: [threat model](docs/security/threat-model.md) · First deploy: [runbook](docs/runbooks/first-deploy.md)
