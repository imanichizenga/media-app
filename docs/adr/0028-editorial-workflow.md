# 0028. Editorial workflow and concurrent editing

Status: accepted, 2026-11-24

## Decision
- **The state machine is data** (`content/workflow.py`): source, target, permission, whether a reason is required. The service enforces it, the admin draws its buttons from it, and the permission matrix test walks all of it.
- **Two guards.** A soft lock (held while the page is open) tells people who is editing and can be taken over, with an audit entry. A version number on every save prevents lost updates even if the lock fails. A decision releases the lock; someone who stays on the page takes it again.
- **Saving.** Every save is a revision; autosaves within a session are merged. Only changed fields are sent, one request at a time. Offline, the words stay in the page and are sent later.
- **The newsroom's clock.** Scheduling, embargo and the calendar use the newsroom's time zone, never the laptop's. Scheduled posts are published by a task every minute with `SKIP LOCKED`.
- **Removing ten or more posts at once** needs a second person when four-eyes is on.

## Alternatives
Real-time co-editing with CRDTs (no demand yet, and every block card would need merge rules); hard locks (a closed laptop blocks breaking news).
