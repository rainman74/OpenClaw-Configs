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
- `BRAVE_SEARCH_API_KEY`
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

### Tool Discovery and Evidence-First Diagnostics (Community Pattern)
- Community-standard agent setups avoid generic "tool not available" statements without command evidence.
- Require explicit discovery commands before declaring a missing capability:
  - `command -v <tool>`
  - `test -x <absolute-path>`
  - `ls -l <absolute-path>` (optional for symlink verification)
- Preferred decision order:
  1. absolute path exists/executable,
  2. PATH lookup in required profile context,
  3. only then declare missing tool.
- Missing-tool reports should include the failed command and exit code/stderr summary.

### Exec Invocation Guard (path vs command)
- `exec` must receive a real command line, not a plain directory/file path.
- Invalid example (will fail): `/volume1/openclaw/skills/`
- Valid examples:
  - `ls -la /volume1/openclaw/skills`
  - `bash /volume1/openclaw/skills/openai-whisper-api/scripts/transcribe.sh /path/to/audio.m4a`
  - `python /volume1/openclaw/skills/openai-image-gen/scripts/gen.py --help`

### Canonical Linux ARM64 Tool Paths (derived from install scripts)
- User home (logical): `/volume1/homes/clawy`
- User home (Synology runtime alias): `/var/services/homes/clawy`
- User-local bin: `/volume1/homes/clawy/.local/bin`
- User bin (runtime-resolved): `/var/services/homes/clawy/bin`
- Entware bin: `/opt/bin`
- OpenClaw root: `/volume1/openclaw`
- Skill root: `/volume1/openclaw/skills`

Canonical binary/script paths:
- Synology note: `/volume1/homes/clawy` and `/var/services/homes/clawy` can resolve to the same home; diagnostics should trust `command -v` output from the active shell context.

- `yt-dlp`: `/volume1/homes/clawy/.local/bin/yt-dlp`
- `ffmpeg`: `/var/services/homes/clawy/bin/ffmpeg` (symlinked to `/usr/bin/ffmpeg` in installer)
- `ffprobe`: `/var/services/homes/clawy/bin/ffprobe`
- `pandoc`: `/var/services/homes/clawy/bin/pandoc`
- `ghostscript` (`gs`): `/opt/bin/gs`
- `deno`: `/volume1/homes/clawy/.local/bin/deno`
- `bird`: `/volume1/homes/clawy/.local/bin/bird`
- `gogcli`: `/volume1/homes/clawy/.local/bin/gogcli`
- `gog`: `/volume1/homes/clawy/.local/bin/gog`
- `gemini`: `/volume1/homes/clawy/.local/bin/gemini`
- `git` (Entware): `/opt/bin/git` (symlinked to `/usr/bin/git` in installer)
- `unzip` (Entware): `/opt/bin/unzip`
- `python3` (Entware): `/opt/bin/python3`
- `matplotlib` (Python module): available via `python3 -c "import matplotlib"`
- `openpyxl` (Python module): available via `python3 -c "import openpyxl"`
- `python-docx` (Python module): available via `python3 -c "import docx"`
- `python-pptx` (Python module): available via `python3 -c "import pptx"`
- `chromium` wrapper (headless/browser runtime): `/volume1/@chromium/bin/chromium-wrapper`
- Whisper skill entry: `/volume1/openclaw/skills/openai-whisper-api/scripts/transcribe.sh`
- Image skill entry: `/volume1/openclaw/skills/openai-image-gen/scripts/gen.py`

Recommended diagnostic preflight (Linux):
```bash
HOME=/volume1/homes/clawy bash -lc '
set -e
command -v yt-dlp || true
command -v ffmpeg || true
command -v ffprobe || true
command -v pandoc || true
command -v gs || true
command -v deno || true
command -v bird || true
command -v gemini || true
command -v gog || true
command -v gogcli || true
command -v git || true
command -v unzip || true
python3 -c "import matplotlib" >/dev/null 2>&1 && echo matplotlib-ok || echo matplotlib-missing
python3 -c "import openpyxl" >/dev/null 2>&1 && echo openpyxl-ok || echo openpyxl-missing
python3 -c "import docx" >/dev/null 2>&1 && echo python-docx-ok || echo python-docx-missing
python3 -c "import pptx" >/dev/null 2>&1 && echo python-pptx-ok || echo python-pptx-missing
[ -x /volume1/@chromium/bin/chromium-wrapper ] && echo chromium-wrapper-ok || echo chromium-wrapper-missing
[ -x /volume1/openclaw/skills/openai-whisper-api/scripts/transcribe.sh ] && echo whisper-script-ok || echo whisper-script-missing
'
```

### Web Access Environment
- Brave Search API integration is available when `BRAVE_SEARCH_API_KEY` is configured.
- Headless Chromium runtime is available via wrapper:
  - `/volume1/@chromium/bin/chromium-wrapper`
- Typical remote-debugging endpoint reference: `http://127.0.0.1:18800/json/list`.
- Preferred web workflow:
  1. discover sources via Brave Search,
  2. open/read target pages with headless browser tooling.

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

### openpyxl Environment (Linux reference)
- Runtime dependency:
  - `python3 -m pip install --user openpyxl`
- Prefix example:
  - `HOME=/volume1/homes/clawy bash -c ". ~/.profile; python3 -c 'import openpyxl'"`
- Scope:
  - Excel read/create/write automation for `.xlsx` / `.xlsm` files (legacy `.xls` should be converted first).

### python-docx Environment (Linux reference)
- Runtime dependency:
  - `python3 -m pip install --user python-docx`
- Prefix example:
  - `HOME=/volume1/homes/clawy bash -c ". ~/.profile; python3 -c 'import docx'"`
- Scope:
  - Word document read/create/write automation for `.docx` files.

### python-pptx Environment (Linux reference)
- Runtime dependency:
  - `python3 -m pip install --user python-pptx`
- Prefix example:
  - `HOME=/volume1/homes/clawy bash -c ". ~/.profile; python3 -c 'import pptx'"`
- Scope:
  - PowerPoint read/create/write automation for `.pptx` files.

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
  - audio-24khz-48kbitrate-mono-mp3
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

### gogcli (Google Workspace CLI binary)
- **Binary/Entry**: `gogcli`
- **Auth/Env**: `GOG_ACCOUNT`, `GOG_KEYRING_PASSWORD`
- **Execution Context**: host PATH/profile context.
- **Notes**: canonical binary installed in `~/.local/bin`, with `gog` symlink for convenience.

### gemini (Google Gemini CLI)
- **Binary/Entry**: `gemini`
- **Auth/Env**: `GEMINI_API_KEY`
- **Execution Context**: host PATH/profile context.
- **Notes**: Gemini CLI integration available when key is configured.

### openpyxl (Python Excel Toolkit)
- **Binary/Entry**: `python3` + `openpyxl` module import.
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: host Python context (recommended preflight: `python3 -c "import openpyxl"`).
- **Notes**: Excel read/create/write workflows for `.xlsx` / `.xlsm` files (legacy `.xls` should be converted first).

### matplotlib (Python plotting toolkit)
- **Binary/Entry**: `python3` + `matplotlib` module import.
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: host Python context (recommended preflight: `python3 -c "import matplotlib"`).
- **Notes**: chart and graph rendering in Python workflows.

### python-docx (Python Word Toolkit)
- **Binary/Entry**: `python3` + `docx` module import.
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: host Python context (recommended preflight: `python3 -c "import docx"`).
- **Notes**: Word document read/create/write workflows for `.docx` files.

### python-pptx (Python PowerPoint Toolkit)
- **Binary/Entry**: `python3` + `pptx` module import.
- **Auth/Env**: no mandatory key in baseline setup.
- **Execution Context**: host Python context (recommended preflight: `python3 -c "import pptx"`).
- **Notes**: PowerPoint read/create/write workflows for `.pptx` files.

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
- **Notes**: supports m4a, audio-24khz-48kbitrate-mono-mp3, ogg, wav, and other Whisper-supported formats.

### fal.ai API integration
- **Binary/Entry**: `curl` against `https://fal.run/fal-ai/...`
- **Auth/Env**: `FAL_AI_KEY`
- **Execution Context**: HTTP POST with JSON payload.
- **Notes**: model references include `fast-sdxl`, `flux-fast`, `sd3-medium`.

### Brave Search API integration
- **Binary/Entry**: OpenClaw Brave web-search integration (API-backed tool call).
- **Auth/Env**: `BRAVE_SEARCH_API_KEY`
- **Execution Context**: normal OpenClaw runtime context.
- **Notes**: use for discovery/search before deep page fetch.

### Image Provider Priority (Unsplash First)
When sourcing images for user requests, the following priority order must be observed:

1. **Primary: Unsplash API** (`UNSPLASH_ACCESS_KEY`)
   - Always attempt Unsplash API first for all image requests
   - Endpoint: `https://api.unsplash.com/`
   - Preferred for: stock photos, landscapes, cityscapes, general imagery

2. **Fallback 1: Pexels API** (`PEXELS_API_KEY`)
   - Use when Unsplash returns insufficient results

3. **Fallback 2: Pixabay API** (`PIXABAY_API_KEY`)
   - Use when both Unsplash and Pexels return insufficient results

4. **Fallback 3: Whitelisted direct hotlink**
   - Use only for allowlisted domains with strict HTTP/content validation

5. **Fallback 4: Wikimedia Commons (strict fallback only)**
   - Use for explicit Commons/historical/CC-specific requests before browser fallback, or when earlier non-browser providers failed
   - Resolve canonical URL via Commons metadata (no guessed hash paths)
   - Reject backend object-store paths such as `/v1/AUTH_...` and any HTML "File not found" responses

6. **Fallback 5: Browser (Headless Chromium, last fallback)**
   - Use only when all API/direct sources are exhausted or when page rendering/screenshot is explicitly required
   - Use `/volume1/@chromium/bin/chromium-wrapper`

**Rationale**: Unsplash/Pexels/Pixabay and validated direct/Commons URLs are preferred for speed and deterministic delivery. Browser automation is the most expensive path and therefore remains the final fallback.

### Chromium headless browser runtime
- **Binary/Entry**: `/volume1/@chromium/bin/chromium-wrapper`
- **Auth/Env**: no dedicated API key; inherits runtime environment.
- **Execution Context**: host runtime; supports headless mode and local CDP debugging.
- **Notes**: canonical fallback for direct page reading and rendering.

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
