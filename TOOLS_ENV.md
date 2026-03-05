# TOOLS_ENV.md

## Purpose
Define environment/runtime requirements, platform-specific setup, dependency expectations, path mappings, command prefixes, and host-level integration notes for tools.

## Scope
Applies to local runtime, host runtime, container runtime, and CI/runtime environments.

## Authority Level
Third authority (subordinate to /MEMORY.md and /TOOLS.md).

## Core Rules
- This file stores environment/runtime constraints only.
- Behavioral policy belongs in /TOOLS.md.
- Global governance/security belongs in /MEMORY.md.
- Keep environment facts centralized here as single source of truth.

### Runtime Compatibility Targets
- Linux ARM64
- Windows x64

### JSON configuration is authoritative (no duplicate maintenance)
- Static OpenClaw key/value settings already defined in `openclaw.json` must **not** be repeated here.
- This document only contains complementary runtime/host notes (binaries, prefixes, external tools, workflows).
- If conflicts occur, the JSON configuration is the technical source of truth for concrete values.

### Required Environment Variables
- `OPENAI_API_KEY` (OpenAI image generation + Whisper transcription)
- `UNSPLASH_ACCESS_KEY`
- `PIXABAY_API_KEY`
- `PEXELS_API_KEY`
- `FAL_AI_KEY`
- `GEMINI_API_KEY`
- `BRAVE_API_KEY`
- `GOG_KEYRING_PASSWORD`
- `GOG_ACCOUNT`


### Workspace and Runtime Path Model
- Canonical workspace roots:
  - Linux: `/volume1/openclaw/workspace`
  - Windows: `D:/Apps/OpenClaw/workspace`
- Runtime directories:
  - processing: `<workspace>/tmp/` (alias forms `tmp/` and `/tmp/` must resolve to this workspace path only)
  - send staging: `<workspace>/send/` (alias forms `send/` and `/send/` must resolve to this workspace path only)
- Message media path format: `<workspace>/send/<file>` (workspace-relative)
- Filesystem-global `/tmp` or `/send` locations outside `<workspace>` are invalid for media workflows.

### OpenClaw CLI Environment (Linux reference)
- OpenClaw CLI invocation prefix:
  ```bash
  PATH="/volume1/homes/clawy/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/syno/bin"
  export HOME="$HOME_DIR"
  nohup node "$HOME_DIR/dist/index.js" [command] <params>
  ```
- Runtime note: `export HOME="$HOME_DIR"` is important so runtime config, credentials, and profile-relative paths resolve to the intended OpenClaw home.

### Bird Environment (Linux reference)
- Binary: `bird` (via PATH)
- Prefix requirement:
  - `HOME=/volume1/homes/clawy bash -lc 'bird [args]'`
- Auth environment:
  - `AUTH_TOKEN`
  - `CT0`
- Runtime note: use `bash -lc` context for this binary.

### yt-dlp / ffmpeg / ffprobe Environment (Linux reference)
- Binaries (via PATH):
  - `yt-dlp`
  - `ffmpeg`
  - `ffprobe`
- Prefix examples:
  - `HOME=/volume1/homes/clawy bash -c ". ~/.profile; yt-dlp [args]..."`
  - `HOME=/volume1/homes/clawy bash -c ". ~/.profile; ffmpeg [args]..."`
  - `HOME=/volume1/homes/clawy bash -c ". ~/.profile; ffprobe [args]..."`
- Runtime availability note: ffmpeg build supports AAC decoder in reference environment.

### OpenAI Image Generation Environment
- Skill/environment integration: `openai-image-gen` configured.
- Script path reference:
  - `/volume1/openclaw/skills/openai-image-gen/scripts/gen.py`
- Example invocation:
  ```bash
  python "/volume1/openclaw/skills/openai-image-gen/scripts/gen.py" \
    --prompt "your prompt here" \
    --model DALL·E-3 \
    --size 1024x1024 \
    --outdir "/volume1/openclaw/workspace/tmp/"
  ```
- Model environment references:
  - `dall-e-3` (quality focus)
  - `dall-e-2` (speed/cost focus)

### OpenAI Whisper Environment
- Skill/environment integration: `openai-whisper-api` configured.
- Script path reference:
  - `/volume1/openclaw/skills/openai-whisper-api/scripts/transcribe.sh`
- Example invocation:
  ```bash
  bash "/volume1/openclaw/skills/openai-whisper-api/scripts/transcribe.sh" /path/to/audio.m4a
  ```
- Format support references:
  - m4a
  - mp3
  - ogg
  - wav
  - other whisper-supported formats

### fal.ai Environment
- Endpoint integration available via configured key.
- Example endpoint usage reference:
  ```bash
  curl --fail --silent --show-error -X POST "https://fal.run/fal-ai/flux-fast" \
    -H "Authorization: Key $FAL_AI_KEY" \
    -H "Content-Type: application/json" \
    -d '{"prompt":"...","image_size":"square_hd"}'
  ```
- Model references:
  - `fast-sdxl`
  - `flux-fast`
  - `sd3-medium`

### Pandoc / Ghostscript / Deno Environment
- pandoc binary reference: `pandoc` (via PATH)
- Ghostscript available in PATH
- Deno binary reference: `deno` (via PATH)
- Deno example:
  ```bash
  deno run --allow-net --allow-read script.ts
  ```
- If a script must write runtime artifacts to workspace processing, allow only that path:
  ```bash
  deno run --allow-net --allow-read --allow-write=<workspace>/tmp/ script.ts
  ```

### Graph Generation Environment
- Runtime dependency references:
  - matplotlib
  - pillow
  - numpy
- Python execution context uses configured HOME/profile in Linux reference runtime.

### Web Publishing Environment
- Web root reference: `/volume1/openclaw/workspace/web/`
- Base URL reference: `https://rainman.synology.me/...`
- Publishing safeguard: never overwrite `index.html`.
- Create dedicated pages for generated outputs (for example `trends.html`, `news.html`).

### Package/Tooling Environment Notes
- Git (reference provisioning in Synology-like hosts):
  ```bash
  opkg update
  opkg install git-http
  ```
- Homebrew path reference: `~/homebrew`
- pnpm path reference: `~/.local/bin/pnpm`
- Skill installation command reference:
  ```bash
  pnpm add -w <skill>
  ```
- Example:
  ```bash
  pnpm add -w bird gemini
  ```
- Skill activation environment notes:
  - update `openclaw.json` skill list/config entries
  - restart gateway runtime

### Local Environment Notes (Examples)
- Cameras:
  - `living-room` → main area, 180° wide angle
  - `front-door` → entrance, motion-triggered
- SSH alias:
  - `home-server` → `192.168.178.5`, user `admin`
- TTS environment defaults:
  - preferred voice: Kathja (Edge TTS)
  - default speaker: Kitchen HomePod


## Available Tools (Unified Environment Inventory)

Standard fields used below:
- **Binary/Entry**: executable or script entry path.
- **Auth/Env**: required environment variables or credential source.
- **Execution Context**: required prefix/profile/runtime context.
- **Notes**: environment-specific capability references.

### OpenClaw CLI
- **Binary/Entry**: `node "$HOME_DIR/dist/index.js"`
- **Auth/Env**: `HOME` should be exported to `"$HOME_DIR"` for predictable runtime config resolution.
- **Execution Context**:
  ```bash
  PATH="/volume1/homes/clawy/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/syno/bin"
  export HOME="$HOME_DIR"
  nohup node "$HOME_DIR/dist/index.js" [command] <params>
  ```
- **Notes**: this is the canonical Linux OpenClaw CLI entrypoint (not `tsx`).

### bird (Twitter/X CLI)
- **Binary/Entry**: `bird`
- **Auth/Env**: `AUTH_TOKEN`, `CT0`
- **Execution Context**: `HOME=/volume1/homes/clawy bash -lc 'bird [args]'`
- **Notes**: version reference `0.8.0`.

### gog (Google Workspace CLI)
- **Binary/Entry**: `gog`
- **Auth/Env**: `GOG_ACCOUNT`, `GOG_KEYRING_PASSWORD`
- **Execution Context**: host PATH/profile context.
- **Notes**: version reference `v0.11.0`; service coverage includes calendar, contacts, docs, drive, gmail, sheets.

### gemini (Google Gemini CLI)
- **Binary/Entry**: `gemini`
- **Auth/Env**: `GEMINI_API_KEY`
- **Execution Context**: host PATH/profile context.
- **Notes**: Gemini CLI integration available when key is configured.

### yt-dlp
- **Binary/Entry**: `yt-dlp`
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: `HOME=/volume1/homes/clawy bash -c ". ~/.profile; yt-dlp [args]..."`
- **Notes**: profile sourcing required in Linux reference runtime.

### ffmpeg
- **Binary/Entry**: `ffmpeg`
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: `HOME=/volume1/homes/clawy bash -c ". ~/.profile; ffmpeg [args]..."`
- **Notes**: reference build supports AAC decoder.

### ffprobe
- **Binary/Entry**: `ffprobe`
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: `HOME=/volume1/homes/clawy bash -c ". ~/.profile; ffprobe [args]..."`
- **Notes**: profile sourcing required in Linux reference runtime.

### pandoc
- **Binary/Entry**: `pandoc`
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: host PATH/profile context.
- **Notes**: available for document conversion workflows.

### Ghostscript
- **Binary/Entry**: `gs` (from PATH)
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: host PATH/profile context.
- **Notes**: runtime availability expected in Linux reference environment.

### Deno
- **Binary/Entry**: `deno`
- **Auth/Env**: permissions via Deno allow flags.
- **Execution Context**:
  ```bash
  deno run --allow-net --allow-read script.ts
  deno run --allow-net --allow-read --allow-write=<workspace>/tmp/ script.ts
  ```
- **Notes**: write access should stay scoped to processing path when artifacts are produced.

### OpenAI Image Generation (skill script)
- **Binary/Entry**: `python /volume1/openclaw/skills/openai-image-gen/scripts/gen.py`
- **Auth/Env**: `OPENAI_API_KEY`
- **Execution Context**: Python runtime with configured key.
- **Notes**: model references `dall-e-3` and `dall-e-2`.

### OpenAI Whisper (skill script)
- **Binary/Entry**: `bash /volume1/openclaw/skills/openai-whisper-api/scripts/transcribe.sh`
- **Auth/Env**: `OPENAI_API_KEY`
- **Execution Context**: Bash runtime with configured key.
- **Notes**: supports m4a, mp3, ogg, wav, and other Whisper-supported formats.

### fal.ai API integration
- **Binary/Entry**: `curl` against `https://fal.run/fal-ai/...`
- **Auth/Env**: `FAL_AI_KEY`
- **Execution Context**: HTTP POST with JSON payload.
- **Notes**: model references include `fast-sdxl`, `flux-fast`, `sd3-medium`.

## Structure
This file intentionally excludes:
- tool behavior policy,
- response contracts,
- failure semantics,
- deterministic selection decisions.
Those belong in /TOOLS.md and /MEMORY.md.

## Platform Notes
### Applies to Windows
- Architecture target: x64.
- OpenClaw command alias reference: `oc [command]`.
- Primary OpenClaw base path: `D:/Apps/OpenClaw`.
- Ensure equivalent dependency/toolchain installation for used tools.
- Preserve workspace-relative media staging semantics.

### Applies to Linux
- Architecture target: ARM64.
- Reference deployment uses `/volume1/...` paths.
- OpenClaw base path: `/volume1/openclaw`.
- Prefix-based execution is required where profile-initialized PATH is needed.
- Ensure runtime availability for node, pnpm bins, yt-dlp, ffmpeg/ffprobe, pandoc, ghostscript, deno.

## Interaction With Other Files
### File Hierarchy
1. /MEMORY.md (highest authority)
2. /TOOLS.md
3. /TOOLS_ENV.md

If conflicts occur:
- /MEMORY.md overrides all
- /TOOLS.md overrides /TOOLS_ENV.md for runtime behavior
- /TOOLS_ENV.md defines only environment constraints

## Change Policy
- Keep content environment/setup/runtime only.
- Preserve valid host/runtime facts; relocate behavior rules to /TOOLS.md.
- Keep Linux/Windows details explicit when different.
- Remove only contradictory/obsolete environment entries.

## Validation Checklist
- [x] Contains environment/runtime/setup requirements only.
- [x] Contains no behavior policy or response contract rules.
- [x] Explicitly covers Linux ARM64 and Windows x64.
- [x] Includes vars, paths, prefixes, binaries, and dependency references.
- [x] No contradictions with /MEMORY.md or /TOOLS.md.
