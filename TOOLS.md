# TOOLS.md

## Purpose
Define tool runtime behavior, invocation discipline, validation contracts, failure handling, deterministic media/runtime workflows, and user-visible output conventions.

## Scope
Applies whenever tools are called or tool outputs are interpreted.

## Authority Level
Second authority (below MEMORY.md, above TOOLS_ENV.md for runtime behavior).

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
- If TOOLS_ENV.md defines a mandatory execution prefix, that prefix is required.
- Runtime rule sections in this file must never be truncated.

### Runtime Response Contract
- `{ ok: true }` (or an explicit documented equivalent) is required before claiming success.
- `{ ok: false }` is failure.
- Missing `ok` (or equivalent explicit success indicator) is failure.
- If a tool call is missing/ambiguous/absent, report:
  - `Tool call did not confirm success.`

### Execution Safety Rules
- Mandatory strict mode for shell scripts:
  - `set -euo pipefail`
  - `IFS=$'\n\t'`
- Use absolute script paths.
- Do not rely on implicit `cd` behavior.
- Use safe quoting (`"${VAR}"`).
- Use JSON heredoc or structurally safe payload encoding for nested JSON.
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
- Returning only text/URL is invalid when direct media delivery is required.
- Markdown image embeds are invalid for message-tool media delivery.
- For media requests, complete the turn with a single final media message.
- If a caption is needed, include exactly one caption in that media message.
- Never send an additional standalone text message that repeats or rephrases the caption/content unless explicitly requested by the user.
- Mandatory deterministic flow:
  1. Download/generate media in `tmp/` processing location.
  2. Validate file exists and size > 0.
  3. Copy to `send/` staging location.
  4. Send with message tool using `send/<file>`.
  5. Wait for explicit success response.
  6. Cleanup only after explicit success confirmation.
- If send confirmation is missing/false:
  - do not cleanup,
  - preserve artifacts,
  - treat operation as failed.
- Cleanup is a state-changing action and follows the same verification requirements as primary tool calls.
- Screenshot runtime rules:
  - capture viewport only,
  - never full-page,
  - maximum one screenshot per step unless explicitly required otherwise,
  - no confirmation screenshot after successful completion.

### Image Selection and Provider Runtime Rules
- Deterministic provider order:
  1. Cache
  2. Unsplash
  3. Pexels
  4. Pixabay
  5. Wikimedia Commons
  6. Whitelisted direct hotlink
  7. Abort
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
- Gmail runtime behavior:
  - prefer HTML body (`<p>`, `<br>`),
  - avoid raw command substitution for body injection,
  - verify UTF-8 correctness for non-ASCII content,
  - validate attachment size/type before send,
  - remove temporary body files after successful send,
  - keep media delivery path behavior aligned with message-tool flow (`send/<file>`).
- TTS runtime behavior:
  - remove internal markers from visible output (`[[tts]]`, `[[/tts]]`, `<tts>`, `</tts>`),
  - TTS markers must never leak into user-visible responses,
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
Those belong in TOOLS_ENV.md.

## Platform Notes
Runtime behavior is platform-neutral.

### Applies to Windows
- Same runtime behavior; use Windows aliases/prefixes from TOOLS_ENV.md.

### Applies to Linux
- Same runtime behavior; use Linux prefixes/paths from TOOLS_ENV.md.


## OpenClaw Community Best Practices (Adopted)
The following commonly used OpenClaw operational practices are explicitly adopted in this file:

- Deterministic execution and no simulated success (`ok`-based confirmation before claims).
- Strict schema adherence (partial payloads are invalid for strict tools).
- Workspace-relative media delivery (`send/<file>`) with staging separation (`tmp/` -> `send/`).
- Cleanup only after explicit send success (no destructive cleanup on uncertain state).
- Deterministic provider fallback order for image sourcing.
- Rate-limit-aware failover and bounded HTTP/tool timeouts.

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
- Keep rules behavior-only.
- Preserve valid existing runtime directives; relocate instead of delete.
- Move setup/path/dependency/platform details to TOOLS_ENV.md.
- Remove only contradictory or duplicate runtime directives.

## Validation Checklist
- [ ] Contains runtime behavior only.
- [ ] Contains no setup/install/dependency provisioning details.
- [ ] Includes response/failure contracts for tool outputs.
- [ ] Includes deterministic media and provider runtime behavior.
- [ ] Preserves prior valid runtime directives unless contradictory.
