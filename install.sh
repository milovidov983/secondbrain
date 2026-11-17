#!/usr/bin/env bash
# secondbrain installer.
#
# Usage:
#   ./install.sh                         install for Claude Code and OpenCode
#   ./install.sh --agent claude|opencode|all   choose the agent (default: all)
#   ./install.sh --vault PATH [options]  also create a vault at PATH (only missing parts, never overwrites)
#   ./install.sh --dry-run ...           show what would happen
#
# Vault options (passed to skills/wiki/scripts/scaffold.sh, see its --help):
#   --preset LIST  --modules LIST  --name NAME  --purpose TEXT  --lang LANGUAGE  --yes
#   ./install.sh --list                  list presets and modules
#
# Safe to re-run: changed skills are backed up to <config-dir>/skills-backup/<timestamp>/ before update.

set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
OPENCODE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
SCAFFOLD="$PACK_DIR/skills/wiki/scripts/scaffold.sh"

AGENT="all" VAULT="" DRY=0 PASS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) AGENT="${2:?--agent needs claude, opencode or all}"; shift 2 ;;
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
case "$AGENT" in claude|opencode|all) ;; *) echo "Unknown agent: $AGENT (use claude, opencode or all)" >&2; exit 1 ;; esac
if [[ -n "$VAULT" ]]; then
  VAULT="${VAULT/#\~/$HOME}"
  case "$VAULT" in /*) ;; *) VAULT="$PWD/$VAULT" ;; esac
fi

run() { if [[ $DRY -eq 1 ]]; then echo "  [dry-run] $*"; else "$@"; fi; }
say() { echo "$@"; }

# --- Skills ------------------------------------------------------------------
install_skills() {  # install_skills <config-dir> <label>
  local cfg="$1" label="$2" skills="$1/skills"
  say "==> Skills ($label) → $skills"
  run mkdir -p "$skills"
  local backup="$cfg/skills-backup/$(date +%Y%m%d-%H%M%S)"
  for src in "$PACK_DIR"/skills/*/; do
    local s dst
    s="$(basename "$src")"; dst="$skills/$s"
    if [[ -d "$dst" ]]; then
      if diff -rq "$src" "$dst" >/dev/null 2>&1; then
        say "  = $s (up to date)"; continue
      fi
      run mkdir -p "$backup"
      run mv "$dst" "$backup/$s"
      say "  ~ $s (updated, old version in $backup/$s)"
    else
      say "  + $s"
    fi
    run cp -r "${src%/}" "$dst"
  done
  run chmod +x "$skills/wiki/scripts/scaffold.sh"
}

# --- Global instructions -------------------------------------------------------
# The section sits between "secondbrain:begin" and "secondbrain:end" markers.
# It is added once; re-running with --vault replaces it to point at the new vault.
section() {
  local p="${VAULT:-not set. Set it with: ./install.sh --vault PATH, or in the workspace AGENTS.md}"
  P="$p" awk '{ i = index($0, "{{VAULT_PATH}}"); if (i) $0 = substr($0, 1, i - 1) ENVIRON["P"] substr($0, i + 14); print }' "$PACK_DIR/global-instructions.md"
}
install_global() {  # install_global <file> <label>
  local global="$1" label="$2"
  say "==> Global instructions ($label) → $global"
  if [[ -f "$global" ]] && grep -q 'secondbrain:begin' "$global"; then
    if [[ -z "$VAULT" ]]; then
      say "  = section already present (re-run with --vault to update the vault path)"
    elif [[ $DRY -eq 1 ]]; then
      say "  [dry-run] replace the secondbrain section (vault: $VAULT)"
    else
      cp "$global" "$global.bak-$(date +%Y%m%d-%H%M%S)"
      local tmp; tmp="$(mktemp)"
      SECT="$(section)" awk '
        /secondbrain:begin/ { print ENVIRON["SECT"]; skip = 1; next }
        /secondbrain:end/   { skip = 0; next }
        !skip { print }' "$global" > "$tmp"
      mv "$tmp" "$global"
      say "  ~ section updated (vault: $VAULT; backup next to the file)"
    fi
  else
    if [[ $DRY -eq 1 ]]; then
      say "  [dry-run] append the secondbrain section to $global"
    else
      mkdir -p "$(dirname "$global")"
      { [[ -s "$global" ]] && printf '\n'; section; } >> "$global"
      say "  + section appended"
    fi
  fi
}

# --- OpenCode slash commands -----------------------------------------------------
# Thin wrappers so /wiki, /save and /inbox work like they do in Claude Code.
install_commands() {
  local cmds="$OPENCODE_DIR/commands"
  say "==> Commands (OpenCode) → $cmds"
  run mkdir -p "$cmds"
  local backup="$OPENCODE_DIR/commands-backup/$(date +%Y%m%d-%H%M%S)"
  write_command() {  # write_command <name> <description> <template>
    local f="$cmds/$1.md"
    if [[ -f "$f" ]] && ! grep -q 'secondbrain' "$f"; then
      say "  = /$1 (kept: existing command not managed by secondbrain)"; return
    fi
    if [[ -f "$f" ]]; then
      run mkdir -p "$backup"
      run cp "$f" "$backup/$1.md"
    fi
    if [[ $DRY -eq 1 ]]; then
      say "  [dry-run] write /$1"
    else
      printf -- '---\ndescription: "%s"\n---\n%s\n' "$2" "$3" > "$f"
      say "  + /$1"
    fi
  }
  write_command wiki "Second brain: setup, onboarding, resume, routing (secondbrain)" \
    'Load the `wiki` skill (secondbrain pack) and follow it. $ARGUMENTS'
  write_command save "Save the current conversation into the wiki vault (secondbrain)" \
    'Load the `wiki-save` skill (secondbrain pack) and save the current conversation into the wiki vault. $ARGUMENTS'
  write_command inbox "Triage the vault Inbox (secondbrain, inbox module)" \
    'Load the `wiki-inbox` skill (secondbrain pack) and triage the vault Inbox. $ARGUMENTS'
}

# --- Run ------------------------------------------------------------------------
if [[ "$AGENT" == claude || "$AGENT" == all ]]; then
  install_skills "$CLAUDE_DIR" "Claude Code"
  install_global "$CLAUDE_DIR/CLAUDE.md" "Claude Code"
fi
if [[ "$AGENT" == opencode || "$AGENT" == all ]]; then
  install_skills "$OPENCODE_DIR" "OpenCode"
  install_global "$OPENCODE_DIR/AGENTS.md" "OpenCode"
  install_commands
fi

# --- Vault (optional) -------------------------------------------------------------
if [[ -n "$VAULT" ]]; then
  bash "$SCAFFOLD" --vault "$VAULT" ${PASS[@]+"${PASS[@]}"}
fi

say ""
say "Done. Next steps:"
if [[ "$AGENT" == claude || "$AGENT" == all ]]; then
  say "  • Restart Claude Code so it picks up the skills (OpenCode reloads them automatically)."
else
  say "  • OpenCode picks up the skills and commands automatically."
fi
if [[ -n "$VAULT" ]]; then
  say "  • cd $VAULT && claude (or opencode), then say \"/wiki\": the agent finishes onboarding (purpose, areas, first sources)."
  say "  • Obsidian: Open folder as vault → $VAULT, then Settings → Appearance → CSS snippets → vault-colors."
else
  say "  • Create a vault: ./install.sh --vault ~/vault   (or ask your agent: \"/wiki set up a vault\")"
fi
