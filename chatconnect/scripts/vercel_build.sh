#!/usr/bin/env bash
# Vercel build for the Guidance Office (counselor) web app.
# Vercel has no Flutter installed, so this downloads it first.
#
# Set these in Vercel → Project → Settings → Environment Variables:
#   SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_WEB_CLIENT_ID (optional)
# They end up inside the public website, so only put public values here
# (the Supabase publishable key and Google client ID are meant to be public).
# Never the Supabase secret/service_role key or the Gemini API key.
set -euo pipefail

FLUTTER_VERSION="3.38.5" # same as local development
FLUTTER_DIR="$HOME/flutter-$FLUTTER_VERSION"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version

# The app reads its settings from a bundled .env file (not in git).
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
KAI_BACKEND_URL=${KAI_BACKEND_URL:-}
GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID:-}
EOF

flutter pub get
flutter build web --release \
  -t lib/main_counselor.dart \
  -o build/web_counselor
