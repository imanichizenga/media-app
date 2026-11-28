# 0052. Subscriptions: stories for subscribers, plans and Snippe

Status: accepted, 2026-11-28. Paid reading on the website and in the apps, through one API.

## Decisions

**A story is for subscribers, or not.** `Post.requires_subscription`, off by default, switched in the editor ("For
subscribers only"). Its card is everyone's, with a small gold "Premium" mark; so are its headline, picture, byline and
opening. Readers who would rather not pay keep the site's top bar, the sections and the tab bar, and go on to free
stories ("Not now, keep reading free stories").

**The lock is on the server.** Published articles are shared by everyone and kept by the CDN and the website's data
cache, so the public article is the story's *opening*: the first `preview_paragraphs` blocks of text (pictures,
video and embeds between them are left out), `locked: true`, and only the assets those blocks use. The whole story is
`GET /api/v1/subscriptions/posts/{id}`, for a signed-in reader with paid time left (402 otherwise), never cached.
Settings → Subscriptions turns the lock off for every story at once, sets the preview's length and which ways of paying
are offered; changing it purges every story for subscribers (tag `premium`).

**The website.** The locked article ends in a fade and an invitation (`components/paywall.tsx`). A signed-in reader's
island (`islands/subscribe.ts`) asks this site's server for the whole story; the server checks the reader's paid time
through the API (renewing their token as it does for everything else) and has an internal-only page draw the body as
the article page draws it (`app/[locale]/subscriber/[post]`, refused without the internal token); the island parses it
inert through a named Trusted Types policy, `subscriber`, and moves the nodes in. Nothing a reader wrote is in it.

**Plans, from the database.** `Plan`: monthly or yearly, a price in whole shillings, a name, a line, what it gives (one
line each, in both languages), an optional badge ("Most popular", "Save 17%"), a colour for its top, which one is chosen
first, whether it is offered, and an order. Admin → Subscriptions makes, changes and hides them (a plan someone paid for
is hidden, never deleted) and lists the payments. A data migration starts the newsroom with three tiers, each monthly
and yearly (ten months' price). The plans page follows Netflix's: a monthly/yearly switch, then cards with the plan's
colour and name on top and its price and what it gives line by line underneath, the chosen one outlined and ticked.

**Snippe, from the database.** An integration like Beem: API key, webhook signing key, webhook address, and for cards a
checkout token and the methods to ask for, in Admin → Integrations, encrypted, with a Test (balance; the signing key).
Docs read on 2026-11-28 (docs.snippe.sh, version 2026-01-25):

- Mobile money: `POST /v1/payments`, `payment_type: "mobile"`, `details.amount` in whole TZS (at least 500),
  `phone_number` without "+", `customer`, `webhook_url`, `metadata`; an `Idempotency-Key` of at most 30 characters (the
  payment's own id). The reader approves the USSD push with their PIN.
- Cards: the documented way to send a reader to Snippe to pay is a Payment Session (`POST /api/v1/sessions`), whose
  `checkout_url` the reader opens and which returns to `redirect_url`. The docs list only `mobile_money` as an
  `allowed_methods` value and use a separate bearer token for sessions, so both are settings: cards are offered only
  when a checkout token is set, and Snippe must confirm card acceptance on the account before it is switched on.
- Webhooks: `X-Webhook-Signature` = hex HMAC-SHA256 with the `whsec_` key over `"{X-Webhook-Timestamp}.{raw body}"`;
  older than five minutes is refused; events are acted on once (`WebhookEvent`), as Snippe may repeat them.

**A payment adds time once.** A completed payment adds the plan's month or year after whatever paid time is left (a
month ends on the same day, or on the last day of a shorter month). Snippe's webhook is what completes it; while the
reader watches, the API also asks Snippe at most every five seconds, in case the webhook is late. Plans do not renew by
themselves: mobile money cannot be charged without the reader's PIN, so a reader pays again for more, and the plans
page says so.

**Locally.** `LOCAL_PAYMENTS=1` completes a payment by itself a few seconds after it starts, without Snippe, so the whole
journey can be tried; a system check refuses it in staging and production, like `LOCAL_SMS`.

## Consequences

- The opening of a locked story is what search engines index; the rest is not public.
- A reader who subscribes on the website is a subscriber in the apps, and the other way round: it is the account's.
- Renewal reminders (push, SMS) before a plan ends are a later step.
