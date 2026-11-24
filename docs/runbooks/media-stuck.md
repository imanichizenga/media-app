# A file stays in Scanning or Processing, or uploads fail

**Uploading stops at 0%.** Browser console shows a blocked request: the bucket's CORS rule must name the admin origin, and the admin task needs `UPLOAD_ORIGIN` (both in `media.tf`, `compute.tf`).

**Scanning.**
1. Does the object have the tag `GuardDutyMalwareScanStatus`? `aws s3api get-object-tagging --bucket <media> --key <original_key>` (the key is in the audit entry).
2. No tag after 10 minutes: GuardDuty → Malware Protection for S3 → the plan must be Active. Its role needs the permissions in `media.tf`.
3. `UNSUPPORTED`, `ACCESS_DENIED` or `FAILED`: the file is rejected on purpose. Never set the tag by hand; the bucket refuses it.
4. After 12 hours the file becomes Failed (`timeout`) and can be retried.

**Processing.**
1. Video: MediaConvert → Jobs, filter by the `asset` metadata. Queue paused, or the job role refused?
2. Pictures: the `worker-media` log, event `media_attempt_failed`.
3. Is `worker-media` running, and is the `media` queue growing ([queue-backlog](queue-backlog.md))?

**Failed** files have a Retry button. After fixing the cause, retry one before the rest.
