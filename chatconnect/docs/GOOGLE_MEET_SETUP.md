# Google Meet setup (counselor web app)

When a counselor clicks **Confirm** on an appointment, the Guidance Office web
app (`lib/main_counselor.dart`) creates an event on the **counselor's** Google
Calendar with a Google Meet link and invites the student by email. Both apps
then show a **Join Google Meet** button.

Until the steps below are done, `GOOGLE_WEB_CLIENT_ID` in `.env` is empty and
the app uses a demo link (it opens the Google Meet home page).

Students never sign in to Google. Only the counselor does, once, in the
browser.

---

## 1. Create a Google Cloud project

1. Go to <https://console.cloud.google.com/> and sign in.
   - Best: use the Google account the Guidance Office will use for meetings
     (a WVSU Google Workspace account if the school has one).
2. Top bar → project picker → **New project** → name it `ChatConnect` →
   **Create**. Make sure it's selected afterwards.

## 2. Turn on the Google Calendar API

1. Left menu → **APIs & Services** → **Library**.
2. Search **Google Calendar API** → open it → **Enable**.

(Google Meet links come from Calendar, so there's no separate Meet API to
enable.)

## 3. Set up the sign-in screen (OAuth consent)

1. Left menu → **APIs & Services** → **OAuth consent screen** (may be called
   **Google Auth Platform**) → **Get started**.
2. **App name:** `ChatConnect Guidance Office`. **Support email:** yours.
3. **Audience:**
   - **Internal** if you created the project inside the WVSU Google Workspace
     organization: any WVSU account can use it, no review needed.
   - Otherwise **External**. While it's in **Testing**, add every counselor's
     Google account under **Audience → Test users** (only those accounts can
     sign in).
4. **Contact information:** your email → **Create**.
5. **Data access** → **Add or remove scopes** → find
   `.../auth/calendar.events` (Google Calendar API, "View and edit events on
   all your calendars") → tick it → **Update** → **Save**.

## 4. Create the web client ID

1. Left menu → **APIs & Services** → **Credentials** (or **Clients**) →
   **Create credentials** → **OAuth client ID**.
2. **Application type:** Web application. **Name:** `Counselor web app`.
3. **Authorized JavaScript origins** → **Add URI**:
   - `http://localhost:5601` (for running it on this computer)
   - later, the real address where the counselor app is hosted
     (e.g. `https://guidance.example.edu.ph`).
   No redirect URIs are needed.
4. **Create** → copy the **Client ID** (ends in
   `.apps.googleusercontent.com`).

## 5. Put the client ID in the app

In `chatconnect/.env`:

```
GOOGLE_WEB_CLIENT_ID=1234567890-abc123.apps.googleusercontent.com
```

## 6. Run and test

The port must match the origin from step 4 exactly:

```
flutter run -d chrome -t lib/main_counselor.dart --web-port 5601
```

1. Sign in to the counselor app (email + password, then staff school ID).
2. Inbox → **Appointments** → **Confirm** on a request →
   **Confirm & create Meet**.
3. The first time, Google shows a pop-up: choose the counselor account →
   **Allow** access to Calendar. (If nothing appears, allow pop-ups for
   `localhost:5601` in the browser.)
4. The appointment becomes **Confirmed** with **Join Google Meet** and
   **Open in Calendar** buttons. The event is on the counselor's Google
   Calendar.

With Supabase connected, the student also gets a Google Calendar invitation
email, and the student app shows **Join Google Meet** on that appointment. In
offline demo mode the sample students have fake emails, so no invitation is
sent.

## Database rule

Run `supabase/migrations/20261110010000_meet_links_by_counselor.sql` in the
Supabase SQL Editor. It makes sure only counselors can set Meet links, so a
student can't put their own link behind the counselor's Join button.

## Common problems

| Problem | Fix |
|---|---|
| Pop-up says `origin_mismatch` or "not a valid origin" | The address in the browser must be listed in **Authorized JavaScript origins** exactly (including the port). |
| "Access blocked: app has not completed verification" | Audience is External: add the account under **Test users**, or use Internal. |
| "Couldn't create the Google Meet" in the app | The pop-up was closed or blocked, or Calendar access wasn't allowed. Try again and click **Allow**. |
| Meet link missing on the event | The account has no Google Meet (some school accounts disable it). Use an account with Meet enabled. |
