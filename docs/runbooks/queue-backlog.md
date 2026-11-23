# Queue backlog, or its measurement missing

**`queue-<name>`: work is waiting.**
1. ECS → the worker service that consumes the queue (`worker_queues` in `compute.tf`). At its maximum? Raise `max` in the environment.
2. Not at its maximum: check the service's events, then the `backlog` scaling activity.
3. At maximum and CPU idle: tasks are waiting on something. Admin → Logs → Integrations shows slow or failing providers; check database CPU.
4. A poison message: the same task name failing repeatedly in the worker log. Fix it, or revoke it.

**`queue-metric-missing`: scaling is blind.**
1. Is `beat` running (exactly one task)? Its log shows `queue-depths` every minute.
2. Do the workers log `queue_depths`? If they log an error, check the task role's `cloudwatch:PutMetricData` and the broker.
3. Until it is fixed, set the worker services' desired count by hand.
