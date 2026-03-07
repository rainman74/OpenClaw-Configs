# BOOT

Workspace bootstrap for OpenClaw.

On startup:

1. Load MEMORY.md
2. Load TOOLS.md and TOOLS_ENV.md
3. Check and clear workspace directories:
   - tmp/
   - send/
4. Verify channels:
   - Telegram
   - Gmail (if enabled)

Notes:

- Do not send messages automatically on startup.
- Do not trigger tools automatically.
- Only prepare runtime state.
