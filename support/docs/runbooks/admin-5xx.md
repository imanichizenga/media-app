# Admin 5xx

1. Find the failing view: log group `/news-<env>/api-admin`, `{ $.event = "unhandled_error" }`.
2. Did a deploy just finish? Re-run the previous deploy (`workflow_dispatch` on the previous commit).
3. Check `/health/ready`: `database: false` → see db-cpu; `redis: false` → new staff sign-ins fail closed by design.
