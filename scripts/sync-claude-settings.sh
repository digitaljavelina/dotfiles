#!/usr/bin/env bash
# Sync ~/.claude/settings.json into the dotfiles repo on demand.
#
# Mirrors the SessionEnd auto-sync hook, for when you change a setting mid-session
# and want it captured now instead of waiting for the session to end.
#
# Usage:
#   sync-claude-settings.sh            # copy live -> dotfiles working copy
#   sync-claude-settings.sh --commit   # also git add + commit + push the change
set -euo pipefail

LIVE="$HOME/.claude/settings.json"
DOT="$HOME/.dotfiles"
TRACKED="$DOT/claude/.claude/settings.json"

[ -f "$LIVE" ] || { echo "no live settings.json at $LIVE"; exit 1; }
[ -d "$DOT/.git" ] || { echo "no dotfiles repo at $DOT"; exit 1; }

if cmp -s "$LIVE" "$TRACKED"; then
  echo "already in sync: $TRACKED"
  exit 0
fi

cp -f "$LIVE" "$TRACKED"
echo "synced -> $TRACKED"

if [ "${1:-}" = "--commit" ]; then
  git -C "$DOT" add claude/.claude/settings.json
  if git -C "$DOT" diff --cached --quiet; then
    echo "nothing to commit (matches HEAD)"
  else
    git -C "$DOT" commit -q -m "claude: sync settings.json"
    git -C "$DOT" push -q origin "$(git -C "$DOT" branch --show-current)"
    echo "committed and pushed"
  fi
else
  echo "tip: re-run with --commit to also commit + push"
fi
