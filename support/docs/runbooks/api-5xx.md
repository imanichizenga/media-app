# API 5xx

1. Log group `/news-<env>/api-public`, `{ $.event = "unhandled_error" }`, correlate by `request_id`.
2. After a deploy: run the previous commit's deploy again.
3. Check RDS and Redis health. The API tolerates a Redis outage; it does not tolerate a database outage.
