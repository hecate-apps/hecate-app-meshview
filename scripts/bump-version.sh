#!/usr/bin/env bash
set -euo pipefail

# Bump version across all MeshView artifacts:
#   - hecate-app-meshviewd/src/hecate_app_meshviewd.app.src
#   - hecate-app-meshviewd/rebar.config (relx release)
#   - hecate-app-meshvieww/package.json

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <new-version>"
    echo "Example: $0 0.2.0"
    exit 1
fi

NEW_VERSION="$1"

# Validate semver format
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be semver (X.Y.Z), got: $NEW_VERSION"
    exit 1
fi

echo "Bumping to version $NEW_VERSION"

# 1. app.src — {vsn, "X.Y.Z"}
APP_SRC="$REPO_ROOT/hecate-app-meshviewd/src/hecate_app_meshviewd.app.src"
sed -i "s/{vsn, \"[0-9]*\.[0-9]*\.[0-9]*\"}/{vsn, \"$NEW_VERSION\"}/" "$APP_SRC"
echo "  Updated $APP_SRC"

# 2. rebar.config — {release, {hecate_app_meshviewd, "X.Y.Z"}
REBAR_CONFIG="$REPO_ROOT/hecate-app-meshviewd/rebar.config"
sed -i "s/{release, {hecate_app_meshviewd, \"[0-9]*\.[0-9]*\.[0-9]*\"}/{release, {hecate_app_meshviewd, \"$NEW_VERSION\"}/" "$REBAR_CONFIG"
echo "  Updated $REBAR_CONFIG"

# 3. package.json — "version": "X.Y.Z"
PACKAGE_JSON="$REPO_ROOT/hecate-app-meshvieww/package.json"
sed -i "s/\"version\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"version\": \"$NEW_VERSION\"/" "$PACKAGE_JSON"
echo "  Updated $PACKAGE_JSON"

echo ""
echo "Version bumped to $NEW_VERSION in all artifacts."
echo "Next steps:"
echo "  1. Update CHANGELOG.md"
echo "  2. git add -A && git commit -m 'chore: Release v$NEW_VERSION'"
echo "  3. git tag v$NEW_VERSION"
echo "  4. git push && git push --tags"
