# Readers' sign-in: set up Beem, Google and Apple

Everything is in the admin: Integrations for the vendors, Settings → Readers' sign-in for the rules. For each vendor:
fill the form, **Save draft**, **Test**, then **Activate**. A way of signing in appears on the website and in the apps
only once it is active and switched on (ADR-0050).

## Beem SMS (phone and code)

1. In Beem (https://login.beem.africa): Profile → Authentication information: copy the **API key** and **Secret key**.
2. Ask Beem to approve a **Sender ID** (at most 11 letters, e.g. `MFANO`). The shared `INFO` no longer works.
3. Admin → Integrations → Beem SMS: API key, secret key, sender ID. **Test** with your own number: it reads the
   balance, checks the sender ID is active, and sends you an SMS.
4. Settings → Readers' sign-in: the countries codes may go to (`255` for Tanzania), the limits, and the hourly
   **budget** of SMS. Keep the budget near your real peak: it stops SMS pumping from emptying the account.
5. Android autofill: put the app's 11-character SMS hash in "Android app hash".

## Sign in with Google

1. Google Cloud Console → APIs & Services → OAuth consent screen: app name, logo, support email, the privacy policy
   and terms pages of the site.
2. Credentials → Create OAuth client ID → **Web application**. Authorised redirect URI:
   `https://<website>/api/auth/google/callback` (exactly, https). Copy the **client ID** and **client secret**.
3. For the apps: an **Android** client (package name and SHA-1) and an **iOS** client (bundle ID). Copy their IDs.
4. Admin → Integrations → Sign in with Google: the four values. **Test**: it reads Google's discovery document and keys,
   and checks Google accepts the web client and its secret.

## Sign in with Apple

1. Apple Developer → Certificates, Identifiers & Profiles → Identifiers: enable **Sign in with Apple** on the app's
   App ID (bundle ID).
2. Create a **Services ID** (e.g. `africa.mfano.web`), enable Sign in with Apple, add the website's domain and the return
   URL `https://<website>/api/auth/apple/callback`.
3. Keys → create a key with Sign in with Apple, download the **.p8** (once only), note its **Key ID** and your
   **Team ID**.
4. Admin → Integrations → Sign in with Apple: Team ID, Key ID, Services ID, bundle ID, and the whole .p8 file pasted
   (line breaks may be lost in the field; they are restored). **Test**: it signs a client secret with the key and checks
   Apple accepts it.

## If a test fails

Each failed step says what to do, in English and Swahili. The call itself is in Integrations → the provider → history,
and in the integration log.
