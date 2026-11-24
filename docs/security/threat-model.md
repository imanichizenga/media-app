# Threat model (M1 scope)

STRIDE per component. Each milestone extends this document. "Test" names the automated proof.

| Component | Threat | Control | Test |
|---|---|---|---|
| Staff sign-in | **S** Stolen password | Mandatory passkey/TOTP; half-open sessions cannot enrol a factor | `test_half_open_session_cannot_enrol_over_existing_mfa` |
| | **S** Phishing | WebAuthn origin and RP binding, user verification required | `test_phishing_origin_is_refused` |
| | **S** Replay of a passkey response | Single-use challenge, independent of the signature counter | `test_replay_is_refused_for_synced_passkeys...` |
| | **S** Code guessing | Per-session, per-user and per-IP limits; single-use codes under concurrency | `test_mfa_guessing_*`, `test_totp_code_spent_once` |
| | **I** Account enumeration | Same response, same hashing work | `test_unknown_and_wrong_password_look_identical` |
| | **D** Locking a victim out | Lockout per account and IP | `test_lockout_is_per_ip...` |
| Session | **S** Stolen cookie | httpOnly, Strict, `__Host-`; device fingerprint; immediate revocation | `test_stolen_cookie_on_another_device...` |
| | **T** CSRF | Exact Origin, session-bound token | `test_foreign_or_missing_origin_refused` |
| Staff sockets | **S** Cross-site WebSocket hijacking | Exact Origin, `SameSite=Strict` cookie | `test_cross_site_socket_is_refused` |
| | **S** Stolen cookie on another device | Single-use ticket issued only after the device check | `test_ticket_of_another_session_is_refused` |
| | **I** Data leaking past a permission | Messages carry no data; topics need their permission | `test_topic_needs_its_permission` |
| | **E** Socket outliving its session | Revalidated every 10 seconds, fails closed | `test_an_ended_session_closes_open_sockets` |
| | **D** Flooding | 4 KB messages, 20 topics, ticket rate limit, 5-second sign-in window | `test_silent_client_is_dropped`, `test_number_of_topics_is_capped` |
| Admin web | **E** XSS | Nonce CSP, Trusted Types, no data in HTML, no tokens in storage | E2E, every page |
| | **T** Open redirect | Same-site path check on `next` | E2E |
| Browser errors | **I** Personal data in reports | Rebuilt from an allowlist, text redacted, no breadcrumbs or replay | `monitoring.test.ts`, E2E |
| | **E** Tunnel used as an open relay | Fixed destination, same-origin only, one event per request, size and rate limits | `monitoring.test.ts` |
| Traces | **I** Query values exported | Stripped before export | `test_query_values_never_reach_a_trace`, `verify-otel.sh` |
| Authorisation | **E** Self-promotion, granting beyond own rights, takeover by reset | Ceiling checks in services, deny by default | `test_rbac.py`, `test_admin_cannot_take_over...` |
| | **E** Invitation outliving its author's authority | Re-checked on acceptance | `test_invite_dies_with_the_inviters_authority` |
| Approvals | **E** Self-approval, swapping the content | CHECK constraint; immutable versions | `test_database_itself_refuses_self_approval`, `test_newer_draft_voids_the_approval` |
| Audit | **R/T** Editing or deleting history | Triggers, DB grants, hash chain, WORM anchor | `test_audit.py`, `test_runtime_role_cannot_rewrite_history` |
| Integrations | **I** Secret disclosure | Write-only, envelope encryption bound to the record, redacted logs and errors | `test_secret_never_leaves_the_server`, `test_ciphertext_is_bound_to_its_record` |
| Outbound HTTP | **I** SSRF, DNS rebinding | Validate and dial the same address; https 443; no redirects | `test_ssrf_*` |
| Edge | **S** Spoofed client IP or country | Right-most trusted hop; origin secret | `test_client_ip_cannot_be_spoofed`, `test_geo_header_without...` |
| Uploads | **E** Malware, polyglots, parser exploits | Scanned before anything opens them; bucket refuses unscanned originals; type from the bytes; confined worker role | `test_an_original_is_never_opened_before_a_clean_remote_verdict`, `uploads_are_scanned_before_anything_opens_them` (Terraform), E2E |
| | **T** Forged scan verdict | Bucket policy lets only the scanner's role write tags | Terraform test |
| | **D** Decompression bomb, endless upload | Pixel limit read from the header; signed part lengths; size limits; pruning | `test_media.py` |
| | **I** Location of a source in a photograph | All metadata removed from every derivative; originals never served | `test_media.py` |
| Article bodies | **E** Stored XSS | Structured blocks, no HTML; one strict schema in three languages; embeds built from parsed addresses | `test_blocks.py`, content fixtures |
| | **T** Link that leaves the site unseen | Protocol-relative, backslash and control-character links refused | `invalid/` fixtures |
| Editing | **E** Publishing without the right | State machine with permission per transition and category scope | Permission matrix in `test_content.py` |
| | **T** Lost updates | Version on every save; soft lock | `test_stale_and_locked_saves_say_so`, E2E |
| | **I** Drafts of other people | Visibility filter in one selector; 404, not 403 | `test_a_journalist_sees_their_own_posts_only`, E2E |
| | **I** Unpublished words through a rebuild | Rebuilds start from the published revision | `test_content.py` |
| | **E** Mass removal by one account | Four-eyes from ten posts | `test_removing_many_needs_a_second_person` |
| Public read API | **I** Personal data in a shared cache | No cookies, no user, explicit public allowlist of routes | `test_platform.py`, `test_public_api.py` |
| | **D** Cache-busting floods | Bounded queries per page, WAF rate limit | Query-count tests |
| Revalidation webhook | **S** Forged or replayed purge | HMAC over time and body, five-minute window (receiver in M2) | Provider Test replays an old request |
| YouTube import | **I** SSRF | Address parsed to an identifier; fixed hosts through the safe client | `test_youtube.py` |
| Exports | **T** CSV injection | Formula neutralising; export is audited first | `test_audit_export...` |
| Supply chain | **T** Malicious dependency | Lockfiles with hashes, denied install scripts, SHA-pinned actions, scanners | CI |

## Accepted risks
- **WORM gap:** entries since the last daily anchor rely on database controls.
- **Root in the AWS account** can replace the running code. Object Lock COMPLIANCE still protects past anchors.
- **HIBP unavailable:** falls back to a local list of common passwords, and logs it.
- **Fingerprint is coarse:** malware on the same machine is out of scope.
- **Egress 443 is open** from tasks (`.trivyignore`).

## Not yet done
OWASP ZAP against staging, and an external penetration test (M11).
