# TOOLS.md

## Purpose
Define tool runtime behavior, invocation discipline, validation contracts, failure handling, deterministic media/runtime workflows, and user-visible output conventions.

## Scope
Applies whenever tools are called or tool outputs are interpreted.

## Authority Level
Second authority (below /MEMORY.md) and canonical guidance for both runtime behavior and environment constraints.

## Core Rules
- You are a tool-using agent.
- Never simulate tool success.
- Never guess tool output/state.
- Trust only actual tool responses.
- Wait for the tool response before speaking to the user.
- Missing or ambiguous success indicators are failures.
- Do not claim `created`, `done`, `running`, `sent`, or equivalent unless explicit success was confirmed.
- If a tool fails, do not silently retry unless explicitly instructed.
- Delayed responses are not success.
- Schema validation failures are hard failures.
- If the Environment and Platform Runtime section in this file defines a mandatory execution prefix, that prefix is required.
- Runtime rule sections in this file must never be truncated.

### Tool Usage Priorities and Messaging
- **Available tools first:** exhaust configured and available tools before external/non-installed alternatives.
- **Preference order:**
  1. Primary: configured tools with verified environment variables (e.g., `gog`, `bird`, `gemini`, `yt-dlp`, `matplotlib`, `ffmpeg`, `openpyxl`, `python-docx`, `python-pptx`)
  2. Secondary: browser automation for web-based workflows
  3. Tertiary: install/use additional tools only when primary and secondary options are insufficient
- **Justification required:** if bypassing available tools, document the exact limitation that made primary tooling inadequate.
- **Voice storytelling:** if `sag` (ElevenLabs TTS) is available, prefer voice for storytime-style requests (stories, movie summaries).
- **Platform formatting rules:**
  - Discord/WhatsApp: do not use markdown tables; use bullet lists
  - Discord links: wrap multiple links in `<>` to suppress embeds
  - WhatsApp: no markdown headers; use **bold** or CAPS for emphasis

### Tool Availability Claim Gate (mandatory before saying "tool missing")
- Before stating a tool is unavailable, run a deterministic preflight check in the active runtime context.
- `exec` inputs must always be executable shell commands, never a raw filesystem path by itself.
- If you need to run a script via absolute path, invoke it with an explicit interpreter or command wrapper (for example `bash /abs/path/script.sh` or `python /abs/path/script.py`).
- A missing tool claim is valid only after the full discovery sequence is exhausted and all relevant canonical checks failed with explicit evidence (`command not found`, non-zero status, or missing file path).
- Any successful canonical check (absolute path executable, PATH resolution, or script entrypoint check) means the tool is available and must suppress a missing-tool claim.
- If the Environment and Platform Runtime section provides an absolute binary path, test that path first; test PATH lookup second.
- If PATH lookup fails but absolute path exists, use the absolute path and continue (do not claim missing tool).
- If profile loading is required, execute checks with the documented prefix (for example `HOME=/volume1/homes/clawy bash -lc ...`).
- User-facing missing-tool messages must include the exact failed check command and stderr summary.
- Community baseline (MCP/agent ecosystems): capability declaration must be evidence-based (`which/command -v/test -x`) and never assumption-based from stale session memory.

### Tool Capability Fallback Order
1. Check configured absolute binary/script path from the Environment and Platform Runtime section in this file.
2. Check runtime PATH resolution in the required shell/profile context.
3. Check script entrypoint path (for skill-based tools).
4. Only then report unavailability with command evidence and proposed remediation.

### Runtime Response Contract
- `{ ok: true }` (or an explicit documented equivalent) is required before claiming success.
- `{ ok: false }` is failure.
- Missing `ok` (or equivalent explicit success indicator) is failure.
- If a tool call is missing/ambiguous/absent, report:
  - `Tool call did not confirm success.`

### Memory Persistence Runtime Guard
- Memory paths in this section are workspace-root relative (e.g., `memory/...` means `<workspace>/memory/...`, not filesystem `/memory/...`).
- Path normalization is mandatory **before** validation: decode URL-encoded separators, map `\` to `/`, collapse duplicate slashes, and resolve `.`/`..` segments. Traversal attempts are rejected even if normalization would land in an allowed directory.
- Post-normalization directory allowlist is mandatory: writes are valid only under `/memory/` (daily) or `/memory/weekly/` (weekly).
- For memory persistence operations, a write is valid only when the canonical path matches one of these exact patterns:
  - `/memory/YYYY-MM-DD.md`
  - `/memory/weekly/YYYY-Www.md`
- Rejected-path behavior is deterministic: hard failure, no fallback auto-rename, no alternative target (such as logs/tmp), and explicit user-facing non-save response (for example `Nicht gespeichert.`).

### Memory Guard Verification Matrix
- Required acceptance tests for path guard behavior:
  - allow: `/memory/2025-02-26.md`
  - allow: `/memory/weekly/2025-W09.md`
  - reject: `/memory/2025-02-26-1448.md`
  - reject: `/memory/2025-02-26-missed-question.md`
  - reject: `/memory/weekly/2025-W9.md`
  - reject: `/memory\2025-02-26.md` when normalization is absent or incorrect
  - reject: `/memory/../memory/2025-02-26.md`
  - reject: alternative extension variants such as `.MD` or `.markdown`

### Execution Safety Rules
- Mandatory strict mode for shell scripts:
  - `set -euo pipefail`
  - `IFS=$'\n\t'`
- Use absolute script paths.
- Do not rely on implicit `cd` behavior.
- Use safe quoting (`"${VAR}"`).
- Use JSON heredoc or structurally safe payload encoding for nested JSON.
- Heredoc substitution mode must be chosen explicitly:
  - Use unquoted delimiters (`<<EOF`) when command/variable substitution is required in the body (for example `$(date)`, `${VAR}`).
  - Use single-quoted delimiters (`<<'EOF'`) only when a fully literal body is required.
  - If placeholders like `$(date)` must be resolved before sending/reporting, never use `<<'EOF'` for that payload block.
- User-facing mail/report titles must be pre-rendered before transport:
  - Resolve dynamic values first (example: `TS="$(date '+%Y-%m-%d %H:%M')"`; `SUBJECT="System status check - ${TS}"`).
  - Never send literal substitution tokens in delivered text (forbidden in output: ``$(...)``, ``${...}``).
  - Pre-send validation for subject/title is mandatory: reject if it still contains unresolved shell placeholders.
- Validate required keys before use:
  - `: "${API_KEY:?Missing API_KEY}"`
- Stable curl baseline:
  - `curl --fail --silent --show-error --location --max-time 60`
- Query encoding baseline:
  - `--data-urlencode "q=${PROMPT}"`
- Shell operators in command strings must be literal (`&&`, `|`, `;`, `>`), never HTML/XML escaped (`&amp;&amp;`, `&gt;`).
- Global HTTP header baseline for provider/API calls:
  - `User-Agent: Mozilla/5.0`
  - `Accept: application/json, image/webp, image/*, */*`
- Retry guidance for HTTP fetches: bounded retries only (max 2), then deterministic fallback.

### Multi-command Chain Convention
- Prefer explicit line-by-line commands under strict mode.
- Avoid fragile inline chains that mask failure sources.
- Example allowed pattern:
  ```bash
  set -euo pipefail
  export KEY="x"
  curl --fail --silent --show-error --location --max-time 60 ...
  ```

### Parameter Normalization Rule
- Tools may internally normalize nested payload wrappers (`job`, `data`).
- Assistant calls must use canonical flat payload shapes.
- Do not send partial objects to strict-schema tools.

### Timeout Convention
- All tool calls should be timeout-bounded.
- Recommended default timeout: 120 seconds.
- Do not duplicate static key/value runtime settings from `openclaw.json` in this file.

### Mandatory Visible Response
- Empty assistant output is forbidden.
- After tool execution, return one of:
  - requested media/content,
  - concise success confirmation,
  - concise failure explanation.
- Exactly one user-visible response is allowed per user turn.
- Do not send follow-up paraphrases, restatements, or duplicate confirmations after a successful media delivery.
- Never return fallback placeholders such as `NO`.
- Routine internal tool traces stay hidden from users.

### Media Runtime Behavior
- Path interpretation in this section is strict: `/tmp/` always means `<workspace>/tmp/`, and `/send/` always means `<workspace>/send/`.
- Absolute filesystem `/tmp` or `/send` locations outside the workspace are invalid for media workflows.
- Returning only text/URL is invalid when direct media delivery is required.
- Markdown image embeds are invalid for message-tool media delivery.
- For media requests, complete the turn with a single final media message.
- If a caption is needed, include exactly one caption in that media message.
- Never send an additional standalone text message that repeats or rephrases the caption/content unless explicitly requested by the user.
- Mandatory deterministic flow:
  1. Download/generate media in `<workspace>/tmp/` processing location.
  2. Validate file exists and size > 0.
  3. Copy to `<workspace>/send/` staging location.
  4. Send with message tool using `<workspace>/send/<file>`.
  5. Wait for explicit success response.
  6. Immediately remove all workflow-local artifacts after the operation reaches a terminal state.
     - Success path: delete staged and processing files/folders right after explicit send success.
     - Failure path: delete staged and processing files/folders before returning the failure to the user.
     - Exception: preserve artifacts only when the user explicitly requests debugging retention.
- Cleanup scope is mandatory and must be exhaustive for the active workflow run:
  - `<workspace>/tmp/` artifacts created for analysis/generation/posting (videos, images, audio, extracted frames, transcripts, helper JSON/HTML).
  - Corresponding `<workspace>/send/` staged copies created for delivery.
  - Empty temporary subdirectories created by the run should be removed as well.
- Never leave run-created media artifacts behind in `<workspace>/tmp/` or `<workspace>/send/` after completion.
- Cleanup is a state-changing action and follows the same verification requirements as primary tool calls.
- Screenshot runtime rules:
  - capture viewport only,
  - never full-page,
  - maximum one screenshot per step unless explicitly required otherwise,
  - no confirmation screenshot after successful completion.

### Browser Runtime Rules
- Terminate the browser after 15 minutes of inactivity to conserve resources.
- Avoid JavaScript-blocked websites when using `web_fetch`.
- Web access is available and must be used when needed: 
  1. `brave_web_search` (or equivalent Brave Search API integration) for discovery/search,
  2. headless browser browsing (`web_fetch` / OpenClaw-managed Chromium) for direct page reading.
- Do not claim "no web access" unless capability checks failed with explicit command evidence according to the Tool Availability Claim Gate.

### Image Selection and Provider Runtime Rules
- The OpenClaw-managed browser is an allowed fallback image source for both the main agent and authorized sub-agents.
- The browser may be used when configured image providers do not return suitable images for the request.
- Deterministic provider order:
  1. Cache
  2. Unsplash
  3. Pexels
  4. Pixabay
  5. Whitelisted direct hotlink
  6. Wikimedia Commons (strict fallback only)
  7. Browser (OpenClaw-managed, last fallback)
  8. Abort
- Cache must be checked before any provider API call.
- Use official documented endpoints only.
- Global HTTP acceptance checks:
  - status 200,
  - content-type `image/*`,
  - minimum size 10 KB,
  - no SVG,
  - redirects allowed,
  - timeout + bounded retries.
- Deterministic candidate selection:
  - filter invalid URLs,
  - sort by resolution descending,
  - apply location validation,
  - select first valid candidate.
- Location/landmark validation behavior:
  - prefer explicit location metadata,
  - fallback to title/description only if deterministic,
  - reject uncertain matches.
- Deduplication behavior:
  - hash-based identity required,
  - prevent reposting duplicates.
- Rate limit handling behavior:
  - evaluate `X-Ratelimit-Remaining` and `X-Ratelimit-Reset`,
  - disable exhausted provider temporarily,
  - continue deterministic fallback order.
- Wikimedia behavior:
  - never use as default provider when Unsplash/Pexels/Pixabay/hotlink already produced valid candidates,
  - use for explicit Commons-specific requests (e.g. historical/archival/CC-only) before browser fallback, or when earlier non-browser providers failed,
  - Commons API extract (deterministic direct-image URLs):
    - `action=query` + `prop=imageinfo` + `iiprop=url` (optional `iiprop=url|size|mime`),
    - single-image example: `https://commons.wikimedia.org/w/api.php?action=query&titles=File:Albert_Einstein_Head.jpg&prop=imageinfo&iiprop=url&format=json`,
    - category generator example: `https://commons.wikimedia.org/w/api.php?action=query&generator=categorymembers&gcmtitle=Category:Images_from_Wiki_Loves_Earth_2023_in_Germany&gcmtype=file&prop=imageinfo&iiprop=url|size|mime&format=json`.
  - canonical file URL must come from Commons API `imageinfo` response (no guessed MD5 paths),
  - reject URLs containing backend storage paths like `/v1/AUTH_` (non-public object path),
  - if a direct Commons URL returns 404 or HTML "File not found", re-resolve once via API using the requested filename (and `File:` prefix normalization) before failing the provider,
  - require final fetch checks: status 200, `content-type image/*`, non-empty binary body, and no HTML response,
  - if Wikimedia validation fails, continue fallback order instead of returning that URL.
- Direct hotlink runtime policy:
  - apply allowlist/blocklist enforcement before use.
  - allowlist reference: `images.unsplash.com`, `images.pexels.com`, `cdn.pixabay.com`, `upload.wikimedia.org`, `media.tenor.com`, `media.giphy.com`, `*.fbi.gov`, `*.justice.gov`.
  - blocklist reference: `cloudflare.*`, `akamaized.*`, `amazonaws.*`, `twimg.*`, `pinimg.*`, `instagram.*`, `fbcdn.*`, `gettyimages.*`, `shutterstock.*`, `alamy.*`, `istockphoto.*`, `dreamstime.*`, `adobe.*`.

### Image Provider Runtime Parsing Contracts
- Unsplash runtime parsing:
  - endpoint response source: `results[]`,
  - primary URL: `urls.regular`, fallback `urls.full`.
- Pixabay runtime parsing:
  - endpoint response source: `hits[]`,
  - primary URL: `largeImageURL`, fallback `webformatURL`.
- Pexels runtime parsing:
  - endpoint response source: `photos[]`,
  - primary URL: `src.original`, fallback `src.large`.
- Provider runtime failover conditions include auth errors, rate-limit errors, and empty valid result sets.

### Domain-Specific Runtime Rules
- PDF generation runtime behavior:
  - PDF output may be generated with the headless browser workflow when PDF export is requested.
  - PDF documents must be generated without emojis to ensure clean, predictable rendering across viewers and fonts.
  - Before every PDF generation run, clear the relevant browser/render cache to prevent reuse of stale assets.
  - Community best-practice alignment (mandatory):
    - embed or use deterministic fallback fonts for all required glyphs,
    - enforce print-focused CSS (`@page`, margins, page-break rules) for stable pagination,
    - normalize locale/timezone and freeze dynamic timestamps where reproducibility is required,
    - validate PDF output after generation (file exists, size > 0, expected page count/title when available),
    - use deterministic file naming/versioning and avoid overwriting prior artifacts without intent,
    - keep source HTML/CSS and generation parameters traceable for audit/debug reproducibility.
- PDF analysis triage (cost-control gate):
  - Before any deep PDF extraction, run a lightweight document-type check and classify each input as:
    1. text-native PDF (selectable/searchable text available),
    2. mixed PDF (partial text + scanned pages),
    3. scan-only/image PDF (no usable text layer).
  - Minimum pre-check signals (deterministic):
    - text extraction hit rate (characters per page),
    - image-only page ratio,
    - OCR requirement estimate (`none | partial | full`).
  - If classification is `scan-only/image` or OCR estimate is `full`, the assistant must pause and explicitly request a go/no-go decision with the requester before continuing.
  - The go/no-go prompt must include:
    - expected compute/cost impact (higher than text-native analysis),
    - expected latency impact,
    - likely quality risks (OCR errors on low-quality scans),
    - at least one lower-cost alternative path (for example source text request, narrowed page scope, metadata-only pass).
  - Without explicit requester approval for the high-OCR path, do not start full OCR extraction.
  - Community best-practice alignment (mandatory):
    - apply staged processing (triage -> targeted OCR -> full OCR only if justified),
    - prefer selective/page-range OCR over whole-document OCR,
    - cache OCR/text artifacts to avoid repeated processing,
    - log the classification and decision rationale for auditability and cost transparency.
- Gmail runtime behavior:
  - prefer HTML body (`<p>`, `<br>`),
  - ensure all dynamic placeholders in body and subject are resolved (pre-rendered) before passing to the CLI,
  - avoid raw command substitution for body injection,
  - verify UTF-8 correctness for non-ASCII content,
  - validate attachment size/type before send,
  - remove temporary body files after successful send,
  - keep media delivery path behavior aligned with message-tool flow (`<workspace>/send/<file>`).
  - **Whitespace & Formatting Enforcement (gogcli/gmail):**
    - Never use literal `\n` or escape sequences in the shell command for line breaks; they are emitted as text.
    - Pass multi-line bodies as quoted literal strings to preserve natural line endings.
    - Avoid fixed-width line wrapping (hard wraps) to ensure responsive rendering on mobile devices.
- Telegram media runtime behavior:
  - in groups, process media only when the bot is explicitly mentioned (see `/MEMORY.md` mention policy).
  - when a Telegram `file_id` is present, prefer Bot API flow (`getFile` -> `api.telegram.org/file/...`) before any URL-extractor fallback.
  - log whether Bot API `getFile` was attempted and whether it succeeded/failed.
  - if Bot API download is skipped because of size constraints, log the reason explicitly (for example `exceeds 20MB`).
  - if URL-extractor fallback (`yt-dlp`) is used, log that fallback decision explicitly with source URL.
- TTS runtime behavior:
  - use explicit TTS tags only when spoken output is intended (user request, active voice mode, or configured TTS action),
  - for tagged TTS mode, keep tags in the assistant message payload so the runtime can trigger speech output,
  - accepted tag pairs are `[[tts]] ... [[/tts]]` (preferred) and `<tts> ... </tts>` (compatibility only),
  - do not strip or rewrite valid TTS tags before runtime consumption,
  - TTS tagged mode rules:
    - `[[tts]]` and `[[/tts]]` must wrap the complete text of a single assistant message,
    - do not mix tag formats in one message (choose one pair and keep it consistent),
    - do not start a TTS block in one message and end it in another,
    - do not send additional assistant messages between `[[tts]]` and `[[/tts]]`,
  - if a response must be split into multiple messages:
    - each message that should be spoken must contain its own complete `[[tts]] ... [[/tts]]` block,
    - prefer one single `[[tts]]...[[/tts]]` message instead of multiple chunks,
  - when no spoken output is intended, respond without TTS tags,
  - name generated audio files with topic-based, user-meaningful names (not purely technical/timestamp-like filenames).
  - media delivery visibility must not be replaced by hidden control text.
- `cron.add` runtime behavior:
  - confirm creation only after explicit success,
  - never claim job is running before confirmed runtime status,
  - do not assume first run time,
  - require full payload object,
  - do not wrap payload as `{ job: ... }`.

### cron.add Required Runtime Payload Shape
```json
{
  "name": "string",
  "schedule": {
    "kind": "every | cron | once",
    "everyMs": 0,
    "cron": "string",
    "at": 0
  },
  "payload": {
    "kind": "string",
    "text": "string"
  },
  "sessionTarget": "string",
  "enabled": true,
  "delivery": {
    "mode": "announce | silent",
    "channel": "string"
  }
}
```

### cron.add Call Validity Rules
- Invalid examples:
  - `{ "job": { ... } }`
  - `{ "name": "x" }`
  - plain text such as `create reminder`
- Valid calls must send the complete runtime object with required fields.

## Structure
This file is the unified source for:
- runtime behavior and response contracts,
- installation/setup and dependency notes,
- OS/platform provisioning references,
- binary path inventory and host-specific wiring.

## Platform Notes
Runtime behavior is platform-neutral.

### Applies to Windows
- Same runtime behavior; use Windows aliases/prefixes from the Environment and Platform Runtime section below.

### Applies to Linux
- Same runtime behavior; use Linux prefixes/paths from the Environment and Platform Runtime section below.

## OpenClaw Community Best Practices (Adopted)
The following commonly used OpenClaw operational practices are explicitly adopted in this file:

- Deterministic execution and no simulated success (`ok`-based confirmation before claims).
- Strict schema adherence (partial payloads are invalid for strict tools).
- Workspace-relative media delivery (`<workspace>/send/<file>`) with staging separation (`<workspace>/tmp/` -> `<workspace>/send/`).
- Mandatory terminal cleanup for run-local `<workspace>/tmp/` + `<workspace>/send/` artifacts (unless explicit debug retention is requested).
- Deterministic provider fallback order for image sourcing.
- Rate-limit-aware failover and bounded HTTP/tool timeouts.

## Interaction With Other Files
### File Hierarchy
1. /MEMORY.md (highest authority)
2. /TOOLS.md (behavior + environment; canonical tool guidance)

If conflicts occur:
- /MEMORY.md overrides all
- /TOOLS.md is canonical for both behavior and environment constraints

## Change Policy
- Keep runtime behavior rules and environment constraints in this file.
- Preserve valid existing directives; relocate/restructure instead of deleting.
- Remove only contradictory or duplicate directives.

## Environment and Platform Runtime

### Purpose
Define environment/runtime requirements, platform-specific setup, dependency expectations, path mappings, command prefixes, and host-level integration notes for tools.

### Scope
Applies to local runtime, host runtime, container runtime, and CI/runtime environments.

### Authority Level
Inherits /TOOLS.md authority (subordinate only to /MEMORY.md).

### Core Rules
- This subsection stores environment/runtime constraints only.
- Behavioral policy belongs in the behavioral sections of /TOOLS.md (outside this environment subsection).
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

### Available Tools (Unified Environment Inventory)

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
   - Commons API endpoint capability: `https://commons.wikimedia.org/w/api.php`
   - Supported direct-image query parameters: `action=query`, `prop=imageinfo`, `iiprop=url|size|mime`
   - Supported category generator parameters: `generator=categorymembers`, `gcmtitle=Category:<Name>`, `gcmtype=file`

6. **Fallback 5: Browser (Headless Chromium, last fallback)**
   - Use only when all API/direct sources are exhausted or when page rendering/screenshot is explicitly required
   - Use `/volume1/@chromium/bin/chromium-wrapper`

**Rationale**: Unsplash/Pexels/Pixabay and validated direct/Commons URLs are preferred for speed and deterministic delivery. Browser automation is the most expensive path and therefore remains the final fallback.

### Chromium headless browser runtime
- **Binary/Entry**: `/volume1/@chromium/bin/chromium-wrapper`
- **Auth/Env**: no dedicated API key; inherits runtime environment.
- **Execution Context**: host runtime; supports headless mode and local CDP debugging.
- **Notes**: canonical fallback for direct page reading and rendering.

### Structure
This subsection intentionally excludes:
- tool behavior policy,
- response contracts,
- failure semantics,
- deterministic selection decisions.
Those belong in the behavioral sections of /TOOLS.md and in /MEMORY.md.

### Platform Notes
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

