# TOOLS_ENV.md

## Purpose
Define environment/runtime requirements, platform-specific setup, dependency expectations, path mappings, command prefixes, and host-level integration notes for tools.

## Scope
Applies to local runtime, host runtime, container runtime, and CI/runtime environments.

## Authority Level
Third authority (subordinate to MEMORY.md and TOOLS.md).

## Core Rules
- This file stores environment/runtime constraints only.
- Behavioral policy belongs in TOOLS.md.
- Global governance/security belongs in MEMORY.md.
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
- `BROWSERLESS_TOKEN`

### Workspace and Runtime Path Model
- Canonical workspace roots:
  - Linux: `/volume1/openclaw/workspace`
  - Windows: `D:/Apps/OpenClaw/workspace`
- Runtime directories:
  - processing: `tmp/`
  - send staging: `send/`
- Message media path format: `send/<file>` (workspace-relative)
- System `/tmp` is allowed for temporary email body files.
- System `/tmp` is not allowed for message media delivery.

### OpenClaw CLI Environment (Linux reference)
- OpenClaw CLI invocation prefix:
  ```bash
  HOME="/volume1/openclaw" \
  OPENCLAW_HOME="/volume1/openclaw" \
  PATH="/volume1/homes/clawy/.local/bin:/usr/local/bin:/usr/local/sbin:/bin:/usr/bin:/usr/syno/bin:/sbin:/usr/sbin:/opt/bin:/opt/sbin:$PATH" \
  /usr/local/bin/tsx /volume1/openclaw/openclaw.mjs [command]
  ```

### Bird / Clawhub Environment (Linux reference)
- Binary paths:
  - `~/.local/share/pnpm/global/5/node_modules/.bin/bird`
  - `~/.local/share/pnpm/global/5/node_modules/.bin/clawhub`
- Prefix requirements:
  - `HOME=/volume1/homes/clawy bash -lc 'bird [args]'`
  - `HOME=/volume1/homes/clawy bash -lc 'clawhub [args]'`
- Runtime note: use `bash -lc` context for these binaries.

### yt-dlp / ffmpeg / ffprobe Environment (Linux reference)
- Binary paths:
  - yt-dlp: `~/.local/bin/yt-dlp`
  - ffmpeg: `~/bin/ffmpeg`
  - ffprobe: `~/bin/ffprobe`
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
- pandoc path reference: `~/bin/pandoc`
- Ghostscript available in PATH
- Deno path reference: `/usr/local/bin/deno` (symlink to `/opt/bin/deno`)
- Deno example:
  ```bash
  deno run --allow-net --allow-read script.ts
  ```
- If a script must write runtime artifacts to workspace processing, allow only that path:
  ```bash
  deno run --allow-net --allow-read --allow-write=tmp/ script.ts
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
  pnpm add -w bird clawhub gemini
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

## Community Best Practices & model-specific phrasing
### General best practices (cross-model)
- Formulate tasks with **goal, context, constraints, and output format**.
- Use clear acceptance criteria (e.g., "max. 5 bullet points", "JSON with no additional text").
- Separate facts from assumptions and mark uncertainty explicitly.
- For tool/code tasks: plan first, execute second, verify third.

### Specific guidance for KIMI-K2.5
- Provide structured prompts with explicit intermediate steps ("Analyze → Plan → Answer").
- Limit scope per request (one primary task instead of multiple goals) to reduce drift.
- For sensitive decisions, request a short risk/trade-off list.

### Specific guidance for Gemini-3-Flash
- Prefer short, precise instructions with a strict output format.
- For long inputs, state prioritization explicitly (e.g., "top 3 points first").
- For higher reliability, add the rule: "If information is missing, state explicitly what is missing."

## Structure
This file intentionally excludes:
- tool behavior policy,
- response contracts,
- failure semantics,
- deterministic selection decisions.
Those belong in TOOLS.md and MEMORY.md.

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
- Ensure runtime availability for tsx, pnpm bins, yt-dlp, ffmpeg/ffprobe, pandoc, ghostscript, deno.

## Interaction With Other Files
### File Hierarchy
1. MEMORY.md (highest authority)
2. TOOLS.md
3. TOOLS_ENV.md

If conflicts occur:
- MEMORY.md overrides all
- TOOLS.md overrides TOOLS_ENV.md for runtime behavior
- TOOLS_ENV.md defines only environment constraints

## Change Policy
- Keep content environment/setup/runtime only.
- Preserve valid host/runtime facts; relocate behavior rules to TOOLS.md.
- Keep Linux/Windows details explicit when different.
- Remove only contradictory/obsolete environment entries.

## Validation Checklist
- [ ] Contains environment/runtime/setup requirements only.
- [ ] Contains no behavior policy or response contract rules.
- [ ] Explicitly covers Linux ARM64 and Windows x64.
- [ ] Includes vars, paths, prefixes, binaries, and dependency references.
- [ ] No contradictions with MEMORY.md or TOOLS.md.
