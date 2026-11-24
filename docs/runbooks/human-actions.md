# Human actions

What only a person can do: accounts, contracts, approvals, physical devices. Nothing here blocks development (two-tier acceptance: LOCAL closes a milestone, STAGING is tracked). **Start the ⏳ items now**: they take days or weeks and cannot be hurried later.

Never paste a credential into an issue, a pull request, a document or a chat. Enter it in the admin console (Integrations → provider → Save as draft → Test → Activate), where it is encrypted and write-only.

Lead times marked † come from user reports or other vendors' guides, not from the vendor itself. Confirm them when you apply.

## Start now

| # | Action | Lead time | Needed for |
|---|---|---|---|
| C0 ⏳ | Company registration documents, and a **D-U-N-S number** whose legal name and address match every form below exactly | Up to 30 days (Google); about 5 business days to issue (Apple), then about 2 to reach Apple | C1, D1 |
| B1 ⏳ | Beem account and **sender ID** registration (TCRA and every operator) | About 2 to 4 weeks† | M4 |
| E1 ⏳ | Meta app and **business verification**, then app review | Days to several weeks† | M10 |
| C1 ⏳ | Apple Developer Program, as an organisation | Weeks have been reported† | M3, M4, M6 |
| D1 ⏳ | Google Play Console, as an organisation | Days, after C0† | M3, M4 |
| A1 | AWS accounts and domain | Hours; af-south-1 is opt-in | M0 STAGING onward |

## A. AWS and domains (M0)

| # | What | Where | Why | Proven by |
|---|---|---|---|---|
| A1 | Accounts for staging and prod (dev optional), MFA on root, billing alarm, af-south-1 enabled | AWS Organizations | Everything in `docs/runbooks/first-deploy.md` | Deploy workflow succeeds (the `not-deployed` job no longer runs) |
| A2 | Domain and a Route 53 hosted zone per environment, for `api.`, `admin.`, `media.` and the website | Registrar, Route 53 | TLS, WebAuthn RP ID, links | `https://<admin host>/healthz` |
| A3 | GitHub environments `staging` and `prod` (required reviewers on prod) and the variables in step 5 of first-deploy | GitHub → Settings | OIDC deploys, no stored keys | Deploy workflow |
| A4 | Branch protection on `main`: require the `required` check | GitHub → Settings | Rule "main stays green" | A red pull request cannot merge |
| A5 | SES: verify the domain (DKIM, SPF, DMARC) and leave the sandbox | SES console | Invitations, resets, alerts | Admin → Integrations → **Email (SES)** → Test |
| A6 | Quotas before load tests: Fargate vCPU, CloudFront, MediaConvert, IVS | Service Quotas | M11 targets | `docs/perf/` |
| A7 | Two people enrolled as Super Admin with passkeys | Admin console | Four-eyes approvals need two | An approval completes |
| A8 | A **dedicated empty test bucket** with all four Block Public Access settings on, an OAC CloudFront distribution, and an IAM user limited to them | AWS | Real-AWS S3 test without touching live media | Admin → Integrations → **S3** → Test |
| A10 | GuardDuty Malware Protection for S3 and MediaConvert available in the region (both are in af-south-1); MediaConvert service quota for concurrent jobs | AWS | Uploads are refused unscanned | Admin → Integrations → **AWS MediaConvert** → Test; one upload becomes Ready |
| A9 | Vendor accounts for Sentry, OpenSearch and ClickHouse Cloud, or agreement to self-manage | Vendors | Errors, M8, M9 | Each provider's Test button |

## B. SMS (M4)

| # | What | Where | Why | Proven by |
|---|---|---|---|---|
| B1 ⏳ | Account, then the brand's sender ID (generic names are refused). Ask Beem for its current forms and delays | beem.africa | Unregistered sender IDs are blocked by Tanzanian operators | **Beem SMS** → Test → Send test SMS |
| B2 | Prepaid balance, low-balance alert, API key and secret | Beem dashboard | OTP, fraud budget | Test → balance step |
| B3 | Delivery report callback URL | Beem dashboard | Delivery status in the SMS log | Status appears in Admin → Logs |

## C. Apple (M3, M4, M6)

| # | What | Where | Why | Proven by |
|---|---|---|---|---|
| C1 ⏳ | Developer Program, organisation | developer.apple.com | Everything on iOS | Team ID exists |
| C2 | App ID, associated domains, Sign in with Apple key (.p8), Service ID | Certificates, Identifiers & Profiles | Guideline 4.8 | **Apple Sign-In** → Test |
| C3 | APNs key, uploaded to Firebase | Same, Firebase | iOS push | **FCM** → Test on an iPhone |
| C4 | App Store Connect record, privacy labels, demo account for review | App Store Connect | Release | TestFlight build installs |
| C5 | App Attest enabled for the App ID | Identifiers | SMS-pumping defence | OTP request attested |

## D. Google (M3, M4, M6)

| # | What | Where | Why | Proven by |
|---|---|---|---|---|
| D1 ⏳ | Play Console, organisation | play.google.com/console | Android release | Internal track installs |
| D2 | Firebase project, service account JSON, web push (VAPID) key | console.firebase.google.com | Push | **FCM** → Test |
| D3 | OAuth consent screen and client IDs: web, Android (upload **and** Play signing SHA-256), iOS | Google Cloud console | Sign in with Google | **Google Sign-In** → Test |
| D4 | Play Integrity API linked; app hash for SMS Retriever from the Play signing key | Play Console | OTP autofill, attestation | OTP fills by itself on a device |
| D5 | Search Console property; News publisher details | search.google.com/search-console | M2 SEO | Sitemap accepted, Rich Results Test |

## E. Meta (M10)

| # | What | Where | Why | Proven by |
|---|---|---|---|---|
| E1 ⏳ | App of type Business, business verification (required for Advanced Access) | developers.facebook.com, business.facebook.com | Instagram sync | Verification badge |
| E2 ⏳ | Instagram professional account linked to the Page; request only the permissions used; screencast for review | App dashboard → App Review | Unneeded permissions are a common rejection reason | **Instagram** → Test lists the granted scopes |

## F. Later

| # | What | Needed for | Proven by |
|---|---|---|---|
| F1 | IVS enabled in a supported region (choose from current AWS documentation) | M7 | **AWS IVS** → Test |
| F2 | AdMob, Ad Manager, Audience Network, AppLovin accounts | M10, only if ads will be used | Provider Test |
| F3 | Turnstile or reCAPTCHA Enterprise keys | M4 | Provider Test |
| F4 | Penetration test vendor | M11 | Report, no open high or critical finding |

## G. People and devices

| # | What | When | Proven by |
|---|---|---|---|
| G1 | Native Swahili editor reviews `docs/i18n/review.md` (regenerate with `node scripts/i18n-review.mjs`) | Before any public release | Every string marked reviewed |
| G2 | Design sign-off. **2026-11-24: layout, structure and components approved with changes D1 to D7** (verbatim in PROGRESS.md). Still open: the three brand themes, then the app (M3). The themes sign-off does not block M3 | At each gate | Written approval, recorded in PROGRESS.md |
| G3 | Mid-range Android phone and an iPhone | M3, M4, M7 | `docs/perf/mobile.md` filled in |
| G4 | Physical security key or phone passkey on the admin console | With staging | Sign-in works |
| G5 | Legal texts: privacy policy, terms, editorial and corrections policies; PDPA registration as a data controller | M2, M4 | Published pages |
| G6 | **Decided 2026-11-24** (verbatim in PROGRESS.md): name, logos and colour are set in the admin; white, red and black, red dominant; three themes, Red Signature by default. Still to do by the client: enter the real name and upload the logos. The app icon, the name under it and the launch screen change with an app release | Before any public release | Admin → Appearance |

## Sources

[Google D-U-N-S](https://support.google.com/googleplay/android-developer/answer/13628312) · [Apple D-U-N-S](https://developer.apple.com/support/D-U-N-S/) · [Meta permissions](https://developers.facebook.com/docs/permissions) · [Instagram app review](https://developers.facebook.com/docs/instagram-platform/app-review) · [AWS: Tanzania sender IDs](https://docs.aws.amazon.com/end-user-messaging/latest/userguide/nx-country-reg-tz.md)
