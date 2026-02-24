# OpenClaw Bot Configs

This repository contains the canonical configuration guidance for a deterministic, secure, reproducible, and fail-safe OpenClaw runtime.

---

## Repository Contents

- `MEMORY.md` — global policy and governance (highest authority)
- `TOOLS.md` — tool runtime behavior and execution contracts
- `TOOLS_ENV.md` — environment setup, paths, binaries, and variables
- (optional) `openclaw_linux.json` / `openclaw_windows.json` — platform-specific JSON configuration when present

---

## Authority and Load Order

1. `MEMORY.md`
2. `TOOLS.md`
3. `TOOLS_ENV.md`

Rules:
- `MEMORY.md` overrides all other files.
- `TOOLS.md` overrides `TOOLS_ENV.md` for runtime behavior.
- `TOOLS_ENV.md` is limited to environment/setup facts.

---


## Guidelines Compliance Check

This repository was reviewed against the official OpenClaw start guidance (`https://docs.openclaw.ai/start/openclaw`) with focus on:
- clear authority hierarchy (`MEMORY.md` > `TOOLS.md` > `TOOLS_ENV.md`),
- strict separation of policy/runtime/environment responsibilities,
- deterministic and verifiable runtime behavior.

Current status: the markdown configuration set is aligned with that model.

## Final Configuration State

### Architecture and Separation of Concerns
- Policy, runtime behavior, and environment details are strictly separated.
- Responsibilities are explicitly assigned to `MEMORY.md`, `TOOLS.md`, and `TOOLS_ENV.md`.
- Runtime behavior is centralized and kept independent from host-specific setup.

### Documentation Consistency
- Duplicates and obsolete references were removed.
- Terminology and structure were aligned for consistent interpretation.
- Platform baselines are documented in the appropriate files.

### Safety and Validation Hardening
- Sensitive configuration changes follow a backup-first workflow.
- Verification is required before claiming success.
- Least-privilege guidance for write access is enforced (for example, scoped Deno write permissions such as `--allow-write=tmp/`).

---

## Core Principles

- **Determinism over randomness**
- **Validation over assumption**
- **Reproducibility over convenience**
- **Fail-safe behavior over silent failure**

If a result cannot be fully verified, it must not be treated as successful.

---

## Runtime Core Rules

- Success may only be reported after explicit confirmation (for example `{ ok: true }` or a documented equivalent).
- Missing or ambiguous success indicators are treated as failures.
- Simulated tool success is forbidden.
- Deterministic media flow uses `tmp/` → `send/` and delivery via `send/<file>`.
- After each completed run (success or failure), all run-local media artifacts in `tmp/` and `send/` must be deleted unless the user explicitly requests debug retention.

---

## Environment Core Rules

- Target platforms: **Linux ARM64** and **Windows x64**.
- JSON configuration files remain authoritative for static key/value settings.
- Markdown files provide complementary runtime and host integration guidance.
- Required API environment variables are documented in `TOOLS_ENV.md`.

---

## Note for Local Synology Setups

Some local installations may require a workspace symlink so expected runtime paths resolve correctly:

```bash
rm -rf /volume1/openclaw/.openclaw/workspace
ln -s /volume1/openclaw/workspace /volume1/openclaw/.openclaw/workspace
```

---

## Repository Goal

Provide a predictable, auditable, and maintainable configuration foundation for stable self-hosted deployments (NAS/server/container) without mixing policy and environment concerns.
