# ChatConnect

Mental health support app for WVSU Pototan Campus students, with an AI
companion (Kai) and a Guidance Office side for counselors.

| Folder | What it is |
|---|---|
| `chatconnect/` | Flutter app. `lib/main.dart` = student app (Android/iOS). `lib/main_counselor.dart` = Guidance Office web app. |
| `chatconnect/supabase/` | Database setup (run `migrations/` in order in the Supabase SQL Editor). |
| `kai-backend/` | FastAPI service that runs Kai's chat (Google Gemini) and crisis keyword filter. |
| `kai-classifier/` | scikit-learn model that tags journal/chat text with a likely theme for Insights. |

## Settings

Each part reads a `.env` file that is **not** in git. Copy the matching
`.env.example` and fill it in. Never commit real keys.

## Hosting the counselor web app on Vercel

`chatconnect/vercel.json` + `chatconnect/scripts/vercel_build.sh` build the
Guidance Office app. In Vercel: import this repo, set **Root Directory** to
`chatconnect`, and add the environment variables `SUPABASE_URL`,
`SUPABASE_ANON_KEY` (publishable key) and optionally `GOOGLE_WEB_CLIENT_ID`.
See `chatconnect/docs/GOOGLE_MEET_SETUP.md` for Google Meet.
