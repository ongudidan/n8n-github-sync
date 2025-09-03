#!/bin/bash

# === CONFIG ===
VOLUME_NAME="n8n_data"
GITHUB_USERNAME="ongudidan"
GITHUB_REPO="n8n-backup"
GITHUB_PAT="ghp_xxxxxxxx"   # <-- replace with your PAT
BRANCH="main"

# === SCRIPT START ===

# Get the volume mountpoint path
VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" -f '{{ .Mountpoint }}')

if [ -z "$VOLUME_PATH" ]; then
    echo "❌ Error: Volume $VOLUME_NAME not found. Creating it..."
    docker volume create "$VOLUME_NAME"
    VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" -f '{{ .Mountpoint }}')
fi

cd "$VOLUME_PATH" || exit 1

# If the folder already has a .git, warn user
if [ -d ".git" ]; then
    echo "⚠️  Warning: This volume already contains a Git repo."
    echo "If you want a clean restore, remove the .git folder first:"
    echo "  rm -rf $VOLUME_PATH/.git"
    exit 1
fi

echo "⬇️  Restoring data from GitHub..."

# Clone repo into a temp folder
TMP_DIR=$(mktemp -d)
git clone -b "$BRANCH" "https://${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git" "$TMP_DIR"

# Copy contents into the volume
cp -r "$TMP_DIR"/. "$VOLUME_PATH"/

# Cleanup
rm -rf "$TMP_DIR"

echo "✅ Restore completed into $VOLUME_PATH"