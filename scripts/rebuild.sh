#!/usr/bin/env bash
set -euo pipefail

# Rebuild meshviewd and sync frontend assets for local dev
#
# Usage: ./scripts/rebuild.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Building frontend ==="
(cd "$REPO_ROOT/hecate-app-meshvieww" && npm run build:lib)

echo ""
echo "=== Syncing frontend to priv/static ==="
PRIV_STATIC="$REPO_ROOT/hecate-app-meshviewd/priv/static"
mkdir -p "$PRIV_STATIC"
cp "$REPO_ROOT/hecate-app-meshvieww/dist/component.js" "$PRIV_STATIC/component.js"

echo ""
echo "=== Syncing manifest.json to priv ==="
cp "$REPO_ROOT/manifest.json" "$REPO_ROOT/hecate-app-meshviewd/priv/manifest.json"

echo ""
echo "=== Compiling daemon ==="
(cd "$REPO_ROOT/hecate-app-meshviewd" && rebar3 compile)

echo ""
echo "Done. Start with: cd hecate-app-meshviewd && rebar3 shell"
