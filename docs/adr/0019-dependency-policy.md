# 0019. Dependency policy

Status: accepted, 2026-11-23

## Context
Dependabot proposed Django 6.1, a Python 3.15 image, a Node 26 image, TypeScript 7 and `@types/node` 26. Some passed CI. All contradict ADR-0002, and passing CI says little about support windows, code generators or production behaviour.

## Decision
- **Django** stays on the current LTS (5.2) until the next LTS. **Python** stays inside `requires-python` (3.14), so even a minor image bump is a deliberate change.
- Majors of Django, Python, Node (image and `@types/node`), TypeScript, Next.js, React, Flutter and Terraform providers are ignored by Dependabot. They are upgraded through an ADR and a pull request of their own.
- `@types/node` follows the Node runtime's major; `@types/react*` follows React's.
- Minor and patch updates are grouped per ecosystem, weekly, after a 7-day cooldown. Other majors arrive as single pull requests.
- Security updates ignore the cooldown. A fix that exists only in an ignored major is found by `pip-audit`, `pnpm audit`, OSV and Trivy, which block CI.
- Flutter is pinned in `ci.yml`, which Dependabot does not read. The `pub` ecosystem is added with `apps/mobile` (M3).

## Alternatives
Accept majors when CI is green; Renovate.

## Consequences
Majors need someone to look for them: review at the start of each milestone. Pull requests 1 to 5 were closed under this policy.
