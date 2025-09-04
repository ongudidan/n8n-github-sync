#!/bin/bash

# === CONFIG ===
VOLUME_NAME="n8n_data"          # Docker volume name (adjust if different)
GITHUB_USERNAME="your-username" # Your GitHub username
GITHUB_REPO="your-repo-name"    # Repo you created for backups
GITHUB_PAT="ghp_xxxxxxxx"       # Your GitHub Personal Access Token (PAT)
BRANCH="main"                   # Branch to restore from

# === AUTO ESCALATE TO ROOT IF NEEDED ===
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Script requires root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# === SCRIPT START ===

# Get the volume mountpoint path
VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" -f '{{ .Mountpoint }}' 2>/dev/null)

if [ -z "$VOLUME_PATH" ]; then
    echo "❌ Volume $VOLUME_NAME not found. Creating it..."
    docker volume create "$VOLUME_NAME" >/dev/null
    VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" -f '{{ .Mountpoint }}')
fi

cd "$VOLUME_PATH" || exit 1

# Remove old Git repo if present (clean restore)
if [ -d ".git" ]; then
    echo "⚠️  Existing Git repo found in $VOLUME_PATH"
    echo "🔄 Removing it for a clean restore..."
    rm -rf .git
fi

echo "⬇️  Restoring data from GitHub..."

# Clone repo into a temp folder
TMP_DIR=$(mktemp -d)
git clone -b "$BRANCH" "https://${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git" "$TMP_DIR"

# Mark as safe (avoid dubious ownership warnings)
git config --global --add safe.directory "$TMP_DIR"

# Copy repo contents into the volume (excluding .git)
rsync -a --exclude='.git' "$TMP_DIR"/ "$VOLUME_PATH"/

# Fix permissions (match n8n container user: node -> 1000:1000)
echo "🔧 Fixing file ownership for n8n..."
chown -R 1000:1000 "$VOLUME_PATH"

# Cleanup
rm -rf "$TMP_DIR"

echo "✅ Restore completed into $VOLUME_PATH"
echo "👉 You can now restart your n8n container: docker restart <container_name>"
