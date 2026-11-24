# Database CPU

1. Performance Insights → top SQL. `log_min_duration_statement` is 500ms.
2. Storage autoscaling and Multi-AZ failover are automatic. Do not fail over for CPU alone.
3. Move tolerant reads to the replica with `use_replica()`.
