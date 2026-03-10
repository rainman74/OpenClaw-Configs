# BOOT

Workspace bootstrap for OpenClaw.

On startup:

1. Load MEMORY.md
2. Load TOOLS.md and TOOLS_ENV.md
3. Clean state directories under `${OPENCLAW_STATE_DIR}` (cross-platform: Windows + Linux):
   - `${OPENCLAW_STATE_DIR}/media/browser`
   - `${OPENCLAW_STATE_DIR}/media/inbound`
   - Delete only files older than 3 days
   - Keep files that are newer than 3 days
4. Clear workspace directories completely (date-independent):
   - `${OPENCLAW_STATE_DIR}/workspace/tmp/`
   - `${OPENCLAW_STATE_DIR}/workspace/send/`
5. Verify channels:
   - Telegram
   - Gmail (if enabled)

Notes:

- Directory rules are OS-agnostic and must work with Linux and Windows path handling.
- Do not send messages automatically on startup.
- Do not trigger tools automatically.
- Only prepare runtime state.
