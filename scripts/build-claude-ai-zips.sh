#!/usr/bin/env bash
# Empacota as skills de .claude/skills em zips para upload no claude.ai
# (Configurações > Capacidades > Skills). Cada skill fica autocontida.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/.claude/skills"
OUT="$ROOT/dist/claude-ai"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
rm -rf "$OUT" && mkdir -p "$OUT"

NOTE='

## Running in claude.ai

There is no `~/.claude/instagram/` folder here. Read `voice.md`, `swipe.md`,
`log.md` and `plan.md` from the project files instead. When this skill says to
write one of those files, give the user the full updated file to download and
tell them to replace it in the project files. `hooks.json` is bundled in this
skill folder wherever `ig-reel/hooks.json` is mentioned.'

for dir in "$SRC"/ig-*; do
  name="$(basename "$dir")"
  cp -r "$dir" "$TMP/$name"
  find "$TMP/$name" -name __pycache__ -prune -exec rm -rf {} +
  case "$name" in
    ig-viral)
      cp "$SRC/ig-reel/hooks.json" "$SRC/ig-reel/hookscore.py" "$TMP/$name/"
      # procura primeiro na própria pasta, depois em ../ig-reel
      python3 - "$TMP/$name/swipe.py" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
s = s.replace('HOOKS = os.path.join(HERE, "..", "ig-reel", "hooks.json")',
              'HOOKS = os.path.join(HERE, "hooks.json")\n'
              'if not os.path.exists(HOOKS):\n'
              '    HOOKS = os.path.join(HERE, "..", "ig-reel", "hooks.json")')
s = s.replace('    sys.path.insert(0, os.path.join(HERE, "..", "ig-reel"))',
              '    sys.path.insert(0, os.path.join(HERE, "..", "ig-reel"))\n'
              '    sys.path.insert(0, HERE)')
open(p, "w", encoding="utf-8").write(s)
PY
      ;;
    ig-plan|ig-audit|ig-repurpose)
      cp "$SRC/ig-reel/hooks.json" "$TMP/$name/" ;;
  esac
  printf '%s\n' "$NOTE" >> "$TMP/$name/SKILL.md"
  (cd "$TMP" && zip -qr "$OUT/$name.zip" "$name")
done
ls -1 "$OUT"
