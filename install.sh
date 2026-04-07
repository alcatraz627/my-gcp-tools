#!/usr/bin/env bash
# install.sh — add gct to PATH by symlinking into /usr/local/bin
# Or source from ~/.zshrc if you prefer not to use symlinks.
#
# Usage: bash install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="/usr/local/bin/gct"

echo "Installing gct from: $REPO_DIR"

# Make all scripts executable
chmod +x "$REPO_DIR/gct"
chmod +x "$REPO_DIR/commands/"*.sh

# Symlink the entrypoint
if [[ -L "$TARGET" ]]; then
  rm "$TARGET"
fi
ln -s "$REPO_DIR/gct" "$TARGET"

echo "✓ gct installed at $TARGET"
echo ""
echo "Run: gct"
echo ""

# Offer to clean up old aliases from zshrc
if grep -q "gcp-inspect\|gcp-use\|gcp-projects\|gcp-ctx\|gcp-pick\|gcp-logs\|gcp-services-all" ~/.zshrc 2>/dev/null; then
  echo "Old gcp-* aliases found in ~/.zshrc."
  echo "You can remove the block between:"
  echo "  # ── GCP / gcloud quick commands ──"
  echo "  # ──────────────────────────────────"
  echo "These are now replaced by gct."
fi
