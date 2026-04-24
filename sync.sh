#!/usr/bin/env bash
# sync.sh — Keep repo and ~/.claude/skills/ in sync
#
# Usage:
#   ./sync.sh to-global   Push changes from this repo → ~/.claude/skills/
#   ./sync.sh to-repo     Pull changes from ~/.claude/skills/ → this repo

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_DIR="$HOME/.claude/skills"

SKILLS=(
  "automation-architect"
  "automation-architect-python"
  "automation-architect-java"
  "automation-architect-mock"
  "automation-architect-nfr"
)

case "${1:-}" in
  to-global)
    echo "Syncing repo → ~/.claude/skills/ ..."
    for skill in "${SKILLS[@]}"; do
      echo "  copying $skill"
      cp -r "$REPO_DIR/$skill" "$GLOBAL_DIR/"
    done
    echo "Done. Global skills updated."
    ;;

  to-repo)
    echo "Syncing ~/.claude/skills/ → repo ..."
    for skill in "${SKILLS[@]}"; do
      echo "  copying $skill"
      cp -r "$GLOBAL_DIR/$skill" "$REPO_DIR/"
    done
    echo "Done. Repo updated."
    ;;

  *)
    echo "Usage: ./sync.sh [to-global | to-repo]"
    echo ""
    echo "  to-global  Copy from this repo to ~/.claude/skills/"
    echo "  to-repo    Copy from ~/.claude/skills/ to this repo"
    exit 1
    ;;
esac
