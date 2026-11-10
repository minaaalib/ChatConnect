# Kai Chat Backend

FastAPI service that puts Gemini behind Kai's persona for the ChatConnect app.
The API key lives only here — never in the Flutter app.

Kai is limited to student wellbeing and using ChatConnect. Off-topic requests
(homework, code, trivia, etc.) are politely declined, and crisis messages always
take priority. The rules live in `SYSTEM_PROMPT` in `main.py`.

## Setup

```bash
cd kai-backend
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # macOS/Linux
pip install -r requirements.txt
copy .env.example .env        # Windows: copy, macOS/Linux: cp
```

Get an API key at https://aistudio.google.com/apikey and paste it into `.env`:

```
GEMINI_API_KEY=your-key-here
```

Optional: set `GEMINI_MODEL` to use a different model (default
`gemini-3.8-flash`; `gemini-3.5-flash-lite` is cheaper).

> **Student privacy:** on Google's free (unpaid) Gemini API tier, submitted
> content may be used to improve Google products and read by human reviewers,
> and Google advises against sending personal information. For a pilot with real
> students, use a paid (billing-enabled) key and confirm the setup with your
> data-privacy officer (RA 10173).

## Run

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

`--host 0.0.0.0` is required so the Android emulator can reach it (the
emulator maps `10.0.2.2` to your machine's `localhost`).

## Test it

```bash
curl http://127.0.0.1:8000/health

curl -X POST http://127.0.0.1:8000/kai-chat ^
  -H "Content-Type: application/json" ^
  -d "{\"session_id\": \"session-kai-main\", \"message\": \"I'm feeling anxious about exams\", \"history\": []}"
```

Try an off-topic message too (e.g. "write me a Python script") — Kai should
decline and steer back to wellbeing.

## Connecting the Flutter app

In `chatconnect/.env`, set:

```
KAI_BACKEND_URL=http://10.0.2.2:8000
```

- `10.0.2.2` — Android emulator (maps to host `localhost`)
- `http://127.0.0.1:8000` — Flutter web / desktop, run on the same machine
- your machine's LAN IP (e.g. `http://192.168.1.20:8000`) — physical device on the same Wi-Fi

If `KAI_BACKEND_URL` is unset or the backend is unreachable, the app falls
back to its built-in canned replies instead of breaking the chat.
