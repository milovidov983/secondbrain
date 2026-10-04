#!/usr/bin/env bash
# Create (or complete) a secondbrain vault. Never overwrites existing files.
#
# Usage:
#   scaffold.sh --vault PATH [options]
#
# Options:
#   --vault PATH        where the vault lives (created if missing)
#   --preset LIST       comma-separated presets (default: general); see --list
#   --modules LIST      comma-separated modules, or "none" (default: none); see --list
#   --name NAME         vault name (default: folder name)
#   --purpose TEXT      one sentence: what the vault is for
#   --lang LANGUAGE     content language (default: English)
#   --yes               do not ask questions, use defaults for anything not given
#   --dry-run           show what would be done
#   --list              list presets and modules, then exit
#
# Without --yes and on an interactive terminal, missing options are asked for.
# Claude runs it non-interactively from the `wiki` skill: scaffold.sh --vault ... --yes

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
A="$SKILL_DIR/assets"

VAULT="" PRESETS="" MODULES="" NAME="" PURPOSE="" LANG_="" YES=0 DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)   VAULT="${2:?--vault needs a path}"; shift 2 ;;
    --preset|--presets) PRESETS="${2:?--preset needs a value}"; shift 2 ;;
    --modules|--module) MODULES="${2:?--modules needs a value}"; shift 2 ;;
    --name)    NAME="${2:?--name needs a value}"; shift 2 ;;
    --purpose) PURPOSE="${2:?--purpose needs a value}"; shift 2 ;;
    --lang)    LANG_="${2:?--lang needs a value}"; shift 2 ;;
    --yes|-y)  YES=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --list)
      echo "Presets:"; for d in "$A"/presets/*/; do printf '  %-10s %s\n' "$(basename "$d")" "$(cat "$d/description")"; done
      echo "Modules:"; for d in "$A"/modules/*/; do printf '  %-10s %s\n' "$(basename "$d")" "$(cat "$d/description")"; done
      exit 0 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

ask() {  # ask <var> <prompt> <default>
  local __v="$1" __p="$2" __d="$3" __a=""
  if [[ $YES -eq 0 && -t 0 ]]; then
    read -r -p "$__p [$__d]: " __a || true
  fi
  printf -v "$__v" '%s' "${__a:-$__d}"
}

if [[ -z "$VAULT" ]]; then
  ask VAULT "Vault path" "$HOME/vault"
fi
VAULT="${VAULT/#\~/$HOME}"
case "$VAULT" in /*) ;; *) VAULT="$PWD/$VAULT" ;; esac

if [[ -z "$PRESETS" && $YES -eq 0 && -t 0 ]]; then
  echo "What is this vault about? Presets add page types and folders on top of the core."
  for d in "$A"/presets/*/; do printf '  %-10s %s\n' "$(basename "$d")" "$(cat "$d/description")"; done
  echo "Combine several with commas, e.g. research,personal."
fi
[[ -n "$PRESETS" ]] || ask PRESETS "Presets" "general"
if [[ -z "$MODULES" && $YES -eq 0 && -t 0 ]]; then
  for d in "$A"/modules/*/; do printf '  %-10s %s\n' "$(basename "$d")" "$(cat "$d/description")"; done
fi
[[ -n "$MODULES" ]] || ask MODULES "Modules (comma-separated, or none)" "none"
[[ -n "$NAME" ]]    || ask NAME "Vault name" "$(basename "$VAULT")"
[[ -n "$PURPOSE" ]] || ask PURPOSE "One sentence: what is this vault for?" "[TODO: one sentence, what this vault is for]"
[[ -n "$LANG_" ]]   || ask LANG_ "Content language" "English"

split() { echo "$1" | tr ',' ' '; }
[[ "$MODULES" == "none" ]] && MODULES=""
for p in $(split "$PRESETS"); do
  [[ -d "$A/presets/$p" ]] || { echo "Unknown preset: $p (see --list)" >&2; exit 1; }
done
for m in $(split "$MODULES"); do
  [[ -d "$A/modules/$m" ]] || { echo "Unknown module: $m (see --list)" >&2; exit 1; }
done

TODAY="$(date +%Y-%m-%d)"
say() { echo "$@"; }
rel() { echo "${1#$VAULT/}"; }
mkd() { [[ -d "$1" ]] && return; if [[ $DRY -eq 1 ]]; then say "  [dry-run] + $(rel "$1")/"; else mkdir -p "$1"; say "  + $(rel "$1")/"; fi; }
put() {  # put <dest> <content>: create the file only if missing
  local dst="$1"; shift
  if [[ -e "$dst" ]]; then say "  = $(rel "$dst")"; return; fi
  if [[ $DRY -eq 1 ]]; then say "  [dry-run] + $(rel "$dst")"; return; fi
  mkdir -p "$(dirname "$dst")"; printf '%s\n' "$*" > "$dst"; say "  + $(rel "$dst")"
}
copy() {  # copy <src> <dest>: only if missing
  if [[ -e "$2" ]]; then say "  = $(rel "$2")"; return; fi
  if [[ $DRY -eq 1 ]]; then say "  [dry-run] + $(rel "$2")"; return; fi
  mkdir -p "$(dirname "$2")"; cp "$1" "$2"; say "  + $(rel "$2")"
}
title() { echo "$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')${1:1}"; }

# --- Collect folders ------------------------------------------------------
# Lines "folder<TAB>description". Core wiki folders first, then presets, then modules.
CORE_WIKI="entities	people, organizations, products, places
concepts	ideas, topics, projects, techniques
sources	one summary page per source document
questions	filed answers and research syntheses
comparisons	side-by-side analyses"
PRESET_WIKI=""   # extra folders under wiki/
for p in $(split "$PRESETS"); do
  while IFS=$'\t' read -r f d; do
    [[ -n "$f" ]] || continue
    printf '%s\n' "$PRESET_WIKI" | cut -f1 | grep -qx "$f" && continue
    PRESET_WIKI="${PRESET_WIKI:+$PRESET_WIKI
}$f	$d"
  done < "$A/presets/$p/folders"
done
MODULE_TOP=""    # extra top-level folders
for m in $(split "$MODULES"); do
  while IFS=$'\t' read -r f d; do
    [[ -n "$f" ]] && MODULE_TOP="${MODULE_TOP:+$MODULE_TOP
}$f	$d"
  done < "$A/modules/$m/folders"
done
wiki_folders() { printf '%s\n' "$CORE_WIKI"; [[ -z "$PRESET_WIKI" ]] || printf '%s\n' "$PRESET_WIKI"; }

say "==> Vault → $VAULT"
say "    presets: $PRESETS · modules: ${MODULES:-none} · language: $LANG_"

# --- Folders ------------------------------------------------------------
mkd "$VAULT"
mkd "$VAULT/.raw"
while IFS=$'\t' read -r f d; do mkd "$VAULT/wiki/$f"; done < <(wiki_folders)
mkd "$VAULT/wiki/meta"
[[ -z "$MODULE_TOP" ]] || while IFS=$'\t' read -r f d; do mkd "$VAULT/$f"; done <<< "$MODULE_TOP"
for d in .raw wiki/questions wiki/comparisons wiki/meta; do
  [[ -n "$(ls -A "$VAULT/$d" 2>/dev/null)" ]] || put "$VAULT/$d/.gitkeep" ""
done
[[ -z "$MODULE_TOP" ]] || while IFS=$'\t' read -r f d; do
  [[ -n "$(ls -A "$VAULT/$f" 2>/dev/null)" ]] || put "$VAULT/$f/.gitkeep" ""
done <<< "$MODULE_TOP"

# --- Templates and Obsidian settings --------------------------------------
for f in "$A"/_templates/*.md; do copy "$f" "$VAULT/_templates/$(basename "$f")"; done
for p in $(split "$PRESETS"); do
  for f in "$A/presets/$p/_templates/"*.md; do [[ -e "$f" ]] && copy "$f" "$VAULT/_templates/$(basename "$f")"; done
done
for m in $(split "$MODULES"); do
  for f in "$A/modules/$m/_templates/"*.md; do [[ -e "$f" ]] && copy "$f" "$VAULT/_templates/$(basename "$f")"; done
done
copy "$A/obsidian/snippets/vault-colors.css" "$VAULT/.obsidian/snippets/vault-colors.css"
copy "$A/obsidian/vault.gitignore" "$VAULT/.gitignore"
put "$VAULT/.obsidian/appearance.json" '{
  "enabledCssSnippets": ["vault-colors"]
}'
put "$VAULT/.obsidian/templates.json" '{
  "folder": "_templates"
}'

# --- CLAUDE.md --------------------------------------------------------------
structure() {
  echo "vault/"
  echo "├── CLAUDE.md          # this file: the vault schema"
  echo "├── .raw/              # immutable source documents (hidden in Obsidian)"
  echo "├── wiki/"
  echo "│   ├── index.md       # master catalog"
  echo "│   ├── log.md         # operation log, newest on top"
  echo "│   ├── hot.md         # ~500-word cache of recent context"
  echo "│   ├── overview.md    # what this vault covers"
  while IFS=$'\t' read -r f d; do printf '│   ├── %-14s # %s\n' "$f/" "$d"; done < <(wiki_folders)
  echo "│   └── meta/          # dashboards, lint reports"
  [[ -z "$MODULE_TOP" ]] || while IFS=$'\t' read -r f d; do printf '├── %-18s # %s\n' "$f/" "$d"; done <<< "$MODULE_TOP"
  echo "└── _templates/        # note templates"
}
join_conv() {  # join_conv <kind> <list>
  local out="" x
  for x in $(split "$2"); do
    out="${out:+$out
}### $x

$(cat "$A/$1/$x/conventions.md")
"
  done
  printf '%s' "${out:-_None._}"
}
render() {  # replace {{KEY}} with $R_KEY; multi-line values allowed
  awk '{
    line = $0; out = ""
    while (match(line, /\{\{[A-Z_]+\}\}/)) {
      key = substr(line, RSTART + 2, RLENGTH - 4)
      out = out substr(line, 1, RSTART - 1) ENVIRON["R_" key]
      line = substr(line, RSTART + RLENGTH)
    }
    print out line
  }' "$1"
}
MOD_OPS=""
for m in $(split "$MODULES"); do
  [[ "$m" == inbox ]] && MOD_OPS='| "process inbox" | Weekly triage of `Inbox/` into tasks, sources and wiki pages after you confirm the plan (`wiki-inbox`) |
'
done
if [[ -e "$VAULT/CLAUDE.md" ]]; then
  say "  = CLAUDE.md (kept; to add a preset, ask Claude: \"add the <name> preset to the vault\")"
elif [[ $DRY -eq 1 ]]; then
  say "  [dry-run] + CLAUDE.md"
else
  R_VAULT_NAME="$NAME" R_PURPOSE="$PURPOSE" R_PRESETS="$PRESETS" R_MODULES="${MODULES:-none}" \
  R_LANGUAGE="$LANG_" R_CREATED="$TODAY" R_STRUCTURE="$(structure)" \
  R_PRESET_CONVENTIONS="$(join_conv presets "$PRESETS")" \
  R_MODULE_CONVENTIONS="$(join_conv modules "$MODULES")" R_MODULE_OPERATIONS="$MOD_OPS" \
    render "$A/vault-CLAUDE.md.template" > "$VAULT/CLAUDE.md"
  say "  + CLAUDE.md"
fi

# --- Starter wiki pages -----------------------------------------------------
fm() { printf -- '---\ntype: meta\ntitle: "%s"\ncreated: %s\nupdated: %s\ntags:\n  - meta\nstatus: seed\n---\n' "$1" "$TODAY" "$TODAY"; }
INDEX_SECTIONS=""
while IFS=$'\t' read -r f d; do
  INDEX_SECTIONS="$INDEX_SECTIONS
## $(title "$f")
_(empty)_
"
done < <(wiki_folders)
put "$VAULT/wiki/index.md" "$(fm Index)
# Index

## Navigation
- [[overview]] · [[hot]] · [[log]]
$INDEX_SECTIONS"
put "$VAULT/wiki/log.md" "$(fm Log)
# Log

Append-only. Newest entries on top.

## [$TODAY] scaffold | Vault created
- Presets: $PRESETS; modules: ${MODULES:-none}"
put "$VAULT/wiki/hot.md" "---
type: meta
title: \"Hot Cache\"
updated: ${TODAY}T00:00:00
---

# Recent Context

## Last Updated
$TODAY. Vault created, no content yet.

## Active Threads
- Onboarding: run \`claude\` in the vault and say \"/wiki\" to finish setup, then ingest the first source."
put "$VAULT/wiki/overview.md" "$(fm Overview)
# Overview

$PURPOSE

## Areas
_Filled in during onboarding and as the vault grows._"
while IFS=$'\t' read -r f d; do
  case "$f" in questions|comparisons) continue ;; esac
  put "$VAULT/wiki/$f/_index.md" "$(fm "$(title "$f") Index")
# $(title "$f")

_(empty)_"
done < <(wiki_folders)

if [[ ! -d "$VAULT/.git" ]]; then
  if [[ $DRY -eq 1 ]]; then say "  [dry-run] git init"; else git -C "$VAULT" init -q && say "  + git init"; fi
fi
