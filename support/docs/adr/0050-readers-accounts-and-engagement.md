# 0050. Readers' accounts and engagement

Status: accepted, 2026-11-27. M4's vertical slice: sign-in (phone and SMS code, Google, Apple), likes, comments,
saves, follows, views and readers, on the website; the apps use the same API.

## Decisions

**Vendors from the database.** Beem SMS, Sign in with Google and Sign in with Apple are integrations like any other:
settings in Admin → Integrations, a Test button that proves them against the vendor, then Activate. A way of signing
in is offered only when it is switched on (Settings → Readers' sign-in) and its vendor is active. Docs read on
2026-11-27: Beem (`docs.beem.africa`: `/v1/send`, `/public/v1/vendors/balance`, `/public/v1/sender-names`, code 100,
numbers without "+", "INFO" disabled), Google (OIDC discovery; `iss` accounts.google.com, `aud` a client ID), Apple
(Sign in with Apple REST: `/auth/authorize`, `/auth/token`, `/auth/keys`, `/auth/revoke`; ES256 client secret).

**Test buttons.** Beem: balance, the sender ID active on the account, a real SMS to the number typed. Google: discovery
and keys, then a made-up code at the token endpoint: `invalid_grant` means the client ID and secret were accepted.
Apple: an ES256 client secret signed with the .p8 key, then the same made-up-code check; the keys.

**SMS codes and fraud.** Six digits from a CSPRNG, kept as an HMAC, five minutes, five tries, used once. Before a code
is sent: allowed countries (calling codes), one code a minute per number, a daily cap per number, an hourly cap per
network, per number range (operator and first digits: SMS pumping), and a site-wide hourly budget. The limiter fails
closed: no Redis, no SMS. All the numbers are settings. Locally `LOCAL_SMS=1` shows the code on screen instead; a
system check refuses it in staging and production.

**Tokens.** A 10-minute HS256 access JWT (key derived from DJANGO_SECRET_KEY for this purpose) and a 60-day refresh
token, random and stored hashed, used once: each use gives the next in its family, and a used one presented again
revokes the family. The apps keep the refresh token in secure storage. The website keeps both in httpOnly, SameSite=Lax
cookies behind its own server (`web/app/api`), so no script ever holds a token; a readable `signed=1` cookie only says
someone is signed in, so shared pages stay one document for everyone. Unsafe requests must carry the site's Origin.

**Google and Apple on the website.** The authorization code flow, never a third-party script on our pages: the site's
server makes state, a nonce and (Google) a PKCE verifier, the API exchanges the code with the client secret and
verifies the identity token (signature against the provider's key set, iss, aud, exp, nonce). Apple answers with
`form_post`, so its state cookie is SameSite=None. The apps send the token their SDK received; its audience is the
Android/iOS client ID or the bundle ID.

**Accounts.** The first sign-in makes the account (no separate sign-up). A verified email links to an existing account;
an unverified one never does. A new reader gives a name and accepts the terms with one tick (consent stored with its
version; a new version asks again). Deletion: signed out everywhere at once, erased after 30 days unless the reader
signs in again; Apple's refresh token is revoked then. Readers can download their data.

**The reader's address.** Through the website's server the API would see the server, so the SMS limits per network
would count the site. The site signs the reader's address with the shared website secret (`X-Reader-Ip`, HMAC); an
unsigned or wrongly signed one is ignored.

**Engagement.** Likes, saves, comments (one level of replies, likes on comments, a writer badge, held when
pre-moderated), follows. The server checks the post's rules at every action (post → category → global, kill switches
first); the client draws only what they allow. Writes are idempotent. Counts come from one Redis hash per post, moved
only when a row really changed, rebuilt from the rows when missing and reconciled hourly.

**Views and readers.** Views: every opening, one device once in 30 minutes. Readers: distinct people in a HyperLogLog
(12 KB per story, within 1%), signed-in readers by account and guests by a random id their browser keeps. Saved to
PostStats every five minutes. Tapping the readers count lists signed-in readers who opened the story, except those who
chose to hide (Account → "Hide my name from reader lists"; the welcome step says names may appear); guests are counted,
never named. Cards show views over their picture, filled after the page arrives, so the CDN keeps one copy.

**Counts on cards** (2026-11-27, asked by the client). Before a story is opened, its card shows views, likes and
comments at the end of its first line, each only once it is above 0. Nothing is drawn over a picture (the client
asked: no eye on images). One switch, Settings → Engagement → "Show counts on story cards", on by default, turns them off everywhere
(`site-config` `engagement.card_counts` for the website, `app-config` `flags.card_counts` for the apps). The counts
answer says per story whether likes and comments are allowed (`likes_on`, `comments_on`, resolved for 50 stories in
two queries), so a card never shows a count its story does not allow. Text size is the reader's own setting (You), so
the stories' action bars no longer carry it.

## Not yet

- The invisible web challenge (Turnstile or reCAPTCHA Enterprise) and app attestation (Play Integrity, App Attest)
  before an SMS: the limits above stand meanwhile.
- The 5k likes/s load test and moving like/bookmark writes to a Redis Stream with batched upserts (SPEC 9.6.1): writes
  go straight to Postgres today, idempotent and indexed.
- Reports, moderation queue and slow mode on hot posts (M5); reposts (off by default).
