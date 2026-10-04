#!/usr/bin/env bash
# secondbrain installer.
#
# Usage:
#   ./install.sh                         install skills + global CLAUDE.md section
#   ./install.sh --vault PATH [options]  also create a vault at PATH (only missing parts, never overwrites)
#   ./install.sh --dry-run ...           show what would happen
#
# Vault options (passed to skills/wiki/scripts/scaffold.sh, see its --help):
#   --preset LIST  --modules LIST  --name NAME  --purpose TEXT  --lang LANGUAGE  --yes
#   ./install.sh --list                  list presets and modules
#
# Safe to re-run: changed skills are backed up to ~/.claude/skills-backup/<timestamp>/ before update.

set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
SCAFFOLD="$PACK_DIR/skills/wiki/scripts/scaffold.sh"

VAULT="" DRY=0 PASS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT="${2:?--vault needs a path}"; shift 2 ;;
    --dry-run) DRY=1; PASS+=(--dry-run); shift ;;
    --preset|--presets|--modules|--module)
      for x in $(echo "${2:?$1 needs a value}" | tr ',' ' '); do
        kind=presets; [[ "$1" == --module* ]] && kind=modules
        [[ "$x" == none || -d "$PACK_DIR/skills/wiki/assets/$kind/$x" ]] || { echo "Unknown ${kind%s}: $x (see --list)" >&2; exit 1; }
      done
      PASS+=("$1" "$2"); shift 2 ;;
    --name|--purpose|--lang) PASS+=("$1" "${2:?$1 needs a value}"); shift 2 ;;
    --yes|-y) PASS+=(--yes); shift ;;
    --list) exec bash "$SCAFFOLD" --list ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done
if [[ -n "$VAULT" ]]; then
  VAULT="${VAULT/#\~/$HOME}"
  case "$VAULT" in /*) ;; *) VAULT="$PWD/$VAULT" ;; esac
fi

run() { if [[ $DRY -eq 1 ]]; then echo "  [dry-run] $*"; else "$@"; fi; }
say() { echo "$@"; }

# --- 1. Skills -------------------------------------------------------------
say "==> Skills → $SKILLS_DIR"
run mkdir -p "$SKILLS_DIR"
BACKUP="$CLAUDE_DIR/skills-backup/$(date +%Y%m%d-%H%M%S)"
for src in "$PACK_DIR"/skills/*/; do
  s="$(basename "$src")"; dst="$SKILLS_DIR/$s"
  if [[ -d "$dst" ]]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then
      say "  = $s (up to date)"; continue
    fi
    run mkdir -p "$BACKUP"
    run mv "$dst" "$BACKUP/$s"
    say "  ~ $s (updated, old version in $BACKUP/$s)"
  else
    say "  + $s"
  fi
  run cp -r "${src%/}" "$dst"
done
run chmod +x "$SKILLS_DIR/wiki/scripts/scaffold.sh"

# --- 2. Global CLAUDE.md ---------------------------------------------------
# The section sits between "secondbrain:begin" and "secondbrain:end" markers.
# It is added once; re-running with --vault replaces it to point at the new vault.
GLOBAL="$CLAUDE_DIR/CLAUDE.md"
say "==> Global instructions → $GLOBAL"
section() {
  local p="${VAULT:-not set. Set it with: ./install.sh --vault PATH, or in the workspace CLAUDE.md}"
  P="$p" awk '{ i = index($0, "{{VAULT_PATH}}"); if (i) $0 = substr($0, 1, i - 1) ENVIRON["P"] substr($0, i + 14); print }' "$PACK_DIR/global-CLAUDE.md"
}
if [[ -f "$GLOBAL" ]] && grep -q 'secondbrain:begin' "$GLOBAL"; then
  if [[ -z "$VAULT" ]]; then
    say "  = section already present (re-run with --vault to update the vault path)"
  elif [[ $DRY -eq 1 ]]; then
    say "  [dry-run] replace the secondbrain section (vault: $VAULT)"
  else
    cp "$GLOBAL" "$GLOBAL.bak-$(date +%Y%m%d-%H%M%S)"
    tmp="$(mktemp)"
    SECT="$(section)" awk '
      /secondbrain:begin/ { print ENVIRON["SECT"]; skip = 1; next }
      /secondbrain:end/   { skip = 0; next }
      !skip { print }' "$GLOBAL" > "$tmp"
    mv "$tmp" "$GLOBAL"
    say "  ~ section updated (vault: $VAULT; backup next to the file)"
  fi
else
  if [[ $DRY -eq 1 ]]; then
    say "  [dry-run] append the secondbrain section to $GLOBAL"
  else
    mkdir -p "$CLAUDE_DIR"
    { [[ -s "$GLOBAL" ]] && printf '\n'; section; } >> "$GLOBAL"
    say "  + section appended"
  fi
fi

# --- 3. Vault (optional) ----------------------------------------------------
if [[ -n "$VAULT" ]]; then
  bash "$SCAFFOLD" --vault "$VAULT" ${PASS[@]+"${PASS[@]}"}
fi

say ""
say "Done. Next steps:"
say "  • Restart Claude Code so it picks up the skills."
if [[ -n "$VAULT" ]]; then
  say "  • cd $VAULT && claude, then say \"/wiki\": Claude finishes onboarding (purpose, areas, first sources)."
  say "  • Obsidian: Open folder as vault → $VAULT, then Settings → Appearance → CSS snippets → vault-colors."
else
  say "  • Create a vault: ./install.sh --vault ~/vault   (or ask Claude: \"/wiki set up a vault\")"
fi
