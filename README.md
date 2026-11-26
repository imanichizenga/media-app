# News platform

| Folder             | What it is                                         |
| ------------------ | -------------------------------------------------- |
| [backend](backend) | The API: Django, Celery, Channels                  |
| [admin](admin)     | The administration console: Next.js                |
| [web](web)         | The public website: Next.js                        |
| [mobile](mobile)   | The Android and iOS app: Flutter                   |
| [support](support) | Everything the four share or need                  |

Inside `support`:

| Folder      | What it is                                                                             |
| ----------- | -------------------------------------------------------------------------------------- |
| `docs`      | Specification, progress, decisions, design, runbooks                                   |
| `packages`  | Shared code: design tokens, UI components, content schema, preview screens             |
| `generated` | API clients written by a generator. Never edited by hand; CI fails when they are stale |
| `tests`     | End-to-end tests. Unit tests live beside the code they test                            |
| `design`    | Design prototypes                                                                      |
| `infra`     | Terraform and Docker                                                                   |
| `scripts`   | Generators and checks                                                                  |

What stays at the top level is there because tools look for it there. Caches, builds and test output are in `.gitignore`. Where older text says `apps/api`, `apps/admin`, `packages` or `docs`, read `backend`, `admin`, `support/packages`, `support/docs`.

Status: [support/docs/PROGRESS.md](support/docs/PROGRESS.md).

## Run locally

Needs Docker, uv, Node 24, pnpm 12.

```sh
docker compose up -d --wait
cd backend && uv sync && export API_SURFACE=admin
uv run python manage.py migrate
uv run python manage.py bootstrap_super_admin you@example.com   # prints a one-time link
uv run uvicorn config.asgi:application --port 8001 &
uv run celery -A config worker -Q critical,default &
cd .. && pnpm install && pnpm --filter @news/design-tokens build
API_PROXY_TARGET=http://127.0.0.1:8001 pnpm --filter @news/admin dev   # http://localhost:3001
```

## Check

| What           | Command                                                                                                 |
| -------------- | ------------------------------------------------------------------------------------------------------- |
| API            | `cd backend && uv run pytest --cov` · `uv run mypy newsplatform config` · `uv run ruff check .`         |
| Web            | `pnpm lint && pnpm typecheck && pnpm test`                                                              |
| End to end     | `API_PROXY_TARGET=http://127.0.0.1:8001 pnpm --filter @news/admin build && pnpm --filter @news/e2e e2e` |
| Infrastructure | `terraform -chdir=support/infra/terraform/modules/platform test`                                        |
| Website        | Build admin as above, then `WEB_LOCAL=1 API_PROXY_TARGET=http://127.0.0.1:8010 pnpm --filter @news/web... build && pnpm --filter @news/e2e web` |
| App            | `support/scripts/mobile-toolchain.sh && . /tmp/toolchain/env && cd mobile && flutter test`             |
| Devices        | CI only: `mobile-device.yml`; Actions → **Soak** runs them N times side by side ([ADR-0048](support/docs/adr/0048-device-tests.md)) |

After changing the API: `manage.py spectacular` (see CI), `pnpm --filter @news/api-client generate`, `support/scripts/generate-dart-client.sh`.

Decisions: [support/docs/adr](support/docs/adr/README.md) · Security: [threat model](support/docs/security/threat-model.md) · First deploy: [runbook](support/docs/runbooks/first-deploy.md)
