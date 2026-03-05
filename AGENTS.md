# AGENTS.md
# Repository Agent Rules for Codex / AI Coding Agents

This file defines strict repository-wide rules for any AI coding agent (Codex, GPT-based agents, etc.).
Agents must follow these rules before performing any changes in the repository.

The goal of these rules is to enforce formatting-only standardization of shell scripts without
changing any functional behavior.

---

# 1. Absolute Restrictions (Never Violate)

Agents are NOT allowed to change runtime behavior.

Forbidden changes:

- Changing logic or control flow
- Adding or removing commands
- Reordering commands
- Changing flags, arguments, URLs, paths, variables, regex, exit codes, or env vars
- Changing quoting
- Changing pipes or redirects
- Changing subshells or command substitutions
- Changing `set -e`, `set -u`, `set -o pipefail`
- Adding new dependencies or external tools
- Refactoring or improving logic

Agents must NOT modify any `.cmd` files.

Only the following files may be modified:

- `*.sh`
- `Windows/*.sh`

---

# 2. Allowed Changes (Cosmetic Only)

Agents may only perform visual formatting changes:

- whitespace
- indentation
- blank lines
- comment formatting
- comment-only section headers
- comment-only chapter separators
- echo message style normalization (without changing meaning)

No other changes are permitted.

---

# 3. Standard Chapter Marker Format

All scripts must use the following chapter marker format:

######################################################################
# Chapter: <TITLE>
######################################################################

Optional subsection markers:

# --- <Subsection Title> ----------------------------------------------------

Rules:

- Chapter markers are comment-only
- No code may be moved
- No behavior may change

Minimum required chapter markers:

- Small scripts: >=3 chapters
- Scripts larger than 120 lines: >=5 chapters

If a script currently has no chapter structure, agents must insert
chapter markers based on existing logical blocks such as:

- Setup
- Configuration
- Functions
- Environment checks
- Main execution
- Cleanup

These markers must be comments only.

---

# 4. Indentation and Whitespace

Shell scripts must follow these formatting rules:

- Use 2 spaces indentation
- No tab characters
- Add blank lines between logical blocks
- Do not move code lines

---

# 5. Comment Normalization

Existing comments must follow the format:

# comment text

Rules:

- Comments must start with '# '
- Do not add new explanatory comments
- Only normalize spacing/formatting

If formatting might change semantics, insert:

# NOTE: Formatting intentionally left unchanged to avoid semantic changes.

---

# 6. Echo Message Formatting

Echo statements must not change meaning.

Allowed transformation examples:

echo "[INFO] message"
echo "[WARN] message"
echo "[ERROR] message"

Rules:

- Do not add or remove echo lines
- Do not convert echo to printf
- Do not change message meaning

---

# 7. Windows ↔ Linux Script Alignment

The following script pairs must share identical chapter structure
(same titles and order):

- start.sh ↔ Windows/ocstart.sh
- update.sh ↔ Windows/ocupdate.sh
- check.sh ↔ Windows/occheck.sh

Requirements:

- Same chapter titles
- Same chapter order
- Similar subsection structure
- Same header style

Only formatting alignment is required.
Commands themselves may differ due to platform differences.

---

# 8. Mandatory Verification (Definition of Done)

Agents must verify compliance using repository commands.

The task is NOT complete until all checks pass.

List all scripts:
git ls-files "*.sh"

Confirm `.cmd` files unchanged:
git ls-files "Windows/*.cmd"

Verify no tabs exist:
grep -R $'\t' --include="*.sh" . || true

Count chapter markers per script:
for f in $(git ls-files "*.sh"); do
  n=$(grep -c '^# Chapter:' "$f" || true)
  lines=$(wc -l < "$f")
  echo "$f chapters=$n lines=$lines"
done

Verify chapter alignment between Linux/Windows pairs:
diff <(grep '^# Chapter:' start.sh) <(grep '^# Chapter:' Windows/ocstart.sh) || true
diff <(grep '^# Chapter:' update.sh) <(grep '^# Chapter:' Windows/ocupdate.sh) || true
diff <(grep '^# Chapter:' check.sh) <(grep '^# Chapter:' Windows/occheck.sh) || true

---

# 9. Completion Gate

The task is considered complete ONLY if:

- All *.sh scripts follow indentation rules
- All *.sh scripts contain the required number of chapter markers
- Linux/Windows script pairs have identical chapter titles
- No `.cmd` files were modified
- No tabs remain in any *.sh

If any verification step fails, the agent must continue editing
until all checks pass.

Partial completion is not acceptable.
