# BOOT

Workspace bootstrap for OpenClaw.

On startup:

1. Load MEMORY.md
2. Load TOOLS.md and TOOLS_ENV.md
3. Delete files in the following state sub-directories:
   - `${OPENCLAW_STATE_DIR}/media/browser`
   - `${OPENCLAW_STATE_DIR}/media/inbound`
4. Delete files in the following workspace sub-directories:
   - `${OPENCLAW_HOME}/workspace/tmp/`
   - `${OPENCLAW_HOME}/workspace/send/`
5. Verify channels:
   - Telegram
   - Gmail (if enabled)

Notes:

- Directory rules are OS-agnostic and must work with Linux and Windows path handling.
- Do not send messages automatically on startup.
- Do not trigger tools automatically.
- Only prepare runtime state.
