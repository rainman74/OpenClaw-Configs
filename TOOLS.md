# TOOLS.md

## Purpose
Define tool runtime behavior, invocation discipline, validation contracts, failure handling, deterministic media/runtime workflows, and user-visible output conventions.

## Scope
Applies whenever tools are called or tool outputs are interpreted.

## Authority Level
Second authority (below /MEMORY.md, above /TOOLS_ENV.md for runtime behavior).

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
- If /TOOLS_ENV.md defines a mandatory execution prefix, that prefix is required.
- Runtime rule sections in this file must never be truncated.

### Tool Availability Claim Gate (mandatory before saying "tool missing")
- Before stating a tool is unavailable, run a deterministic preflight check in the active runtime context.
- A missing tool claim is valid only after the full discovery sequence is exhausted and all relevant canonical checks failed with explicit evidence (`command not found`, non-zero status, or missing file path).
- Any successful canonical check (absolute path executable, PATH resolution, or script entrypoint check) means the tool is available and must suppress a missing-tool claim.
- If `TOOLS_ENV.md` provides an absolute binary path, test that path first; test PATH lookup second.
- If PATH lookup fails but absolute path exists, use the absolute path and continue (do not claim missing tool).
- If profile loading is required, execute checks with the documented prefix (for example `HOME=/volume1/homes/clawy bash -lc ...`).
- User-facing missing-tool messages must include the exact failed check command and stderr summary.
- Community baseline (MCP/agent ecosystems): capability declaration must be evidence-based (`which/command -v/test -x`) and never assumption-based from stale session memory.

### Tool Capability Fallback Order
1. Check configured absolute binary/script path from `TOOLS_ENV.md`.
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
  - Resolve dynamic values first (example: `TS="$(date '+%Y-%m-%d %H:%M')"`; `SUBJECT="Systemstatus-Prüfung - ${TS}"`).
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
  5. Wikimedia Commons
  6. Whitelisted direct hotlink
  7. Browser (OpenClaw-managed)
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
  - resolve direct upload URL from File page,
  - never guess MD5 path,
  - validate final URL with content checks.
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
  - avoid raw command substitution for body injection,
  - verify UTF-8 correctness for non-ASCII content,
  - validate attachment size/type before send,
  - remove temporary body files after successful send,
  - keep media delivery path behavior aligned with message-tool flow (`<workspace>/send/<file>`).
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
This file intentionally excludes:
- installation/setup steps,
- dependency installation,
- OS/platform provisioning,
- binary path inventory and host-specific wiring.
Those belong in /TOOLS_ENV.md.

## Platform Notes
Runtime behavior is platform-neutral.

### Applies to Windows
- Same runtime behavior; use Windows aliases/prefixes from /TOOLS_ENV.md.

### Applies to Linux
- Same runtime behavior; use Linux prefixes/paths from /TOOLS_ENV.md.


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
2. /TOOLS.md
3. /TOOLS_ENV.md

If conflicts occur:
- /MEMORY.md overrides all
- /TOOLS.md overrides /TOOLS_ENV.md for runtime behavior
- /TOOLS_ENV.md defines only environment constraints

## Change Policy
- Keep rules behavior-only.
- Preserve valid existing runtime directives; relocate instead of delete.
- Move setup/path/dependency/platform details to /TOOLS_ENV.md.
- Remove only contradictory or duplicate runtime directives.

## Validation Checklist
- [x] Contains runtime behavior only.
- [x] Contains no setup/install/dependency provisioning details.
- [x] Includes response/failure contracts for tool outputs.
- [x] Includes deterministic media and provider runtime behavior.
- [x] Preserves prior valid runtime directives unless contradictory.
