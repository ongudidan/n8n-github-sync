#!/bin/bash

# === CONFIG ===
VOLUME_NAME="n8n_data"          # Docker volume name (adjust if different)
GITHUB_USERNAME="your-username" # Your GitHub username
GITHUB_REPO="your-repo-name"    # Repo you created for backups
GITHUB_PAT="ghp_xxxxxxxx"       # Your GitHub Personal Access Token (PAT)
BRANCH="main"                   # Branch to use in the repo

# === AUTO ESCALATE TO ROOT IF NEEDED ===
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Script requires root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# === SCRIPT START ===

# Get the volume mountpoint path
VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" -f '{{ .Mountpoint }}' 2>/dev/null)

if [ -z "$VOLUME_PATH" ]; then
    echo "❌ Error: Volume $VOLUME_NAME not found."
    exit 1
fi

cd "$VOLUME_PATH" || exit 1

# Mark directory as safe for git (avoids dubious ownership errors)
git config --global --add safe.directory "$VOLUME_PATH"

# Force Git identity (works even under sudo/root)
git config --local user.email "backup-bot@example.com"
git config --local user.name "n8n Backup Bot"

# If this is the first time (no .git folder)
if [ ! -d ".git" ]; then
    echo "🚀 Initializing Git repo in $VOLUME_PATH"

    git init

    # Ensure branch exists
    git checkout -b "$BRANCH"

    git remote add origin "https://${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"

    git add .
    git commit -m "Initial backup: $(date '+%Y-%m-%d %H:%M:%S')"
    git push -u origin "$BRANCH"

else
    echo "🔄 Repository already initialized. Checking for changes..."

    # Ensure we are on the correct branch
    if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
        git checkout -b "$BRANCH"
    else
        git checkout "$BRANCH"
    fi

    git add .

    # Only commit if changes exist
    if ! git diff --cached --quiet; then
        git commit -m "Auto backup: $(date '+%Y-%m-%d %H:%M:%S')"
        git push origin "$BRANCH" || git push origin HEAD:"$BRANCH"
    else
        echo "✅ No changes to commit."
    fi
fi
