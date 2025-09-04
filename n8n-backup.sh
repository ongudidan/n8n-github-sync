#!/bin/bash

# === CONFIG ===
VOLUME_NAME="n8n_data"          # Docker volume name (adjust if different)
GITHUB_USERNAME="your-username" # Your GitHub username
GITHUB_REPO="your-repo-name"    # Repo you created for backups
GITHUB_PAT="ghp_xxxxxxxx"       # Your GitHub Personal Access Token (PAT)
BRANCH="main"                   # Branch to use in the repo

# === SCRIPT START ===

# Get the volume mountpoint path
VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" -f '{{ .Mountpoint }}')

if [ -z "$VOLUME_PATH" ]; then
    echo "❌ Error: Volume $VOLUME_NAME not found."
    exit 1
fi

cd "$VOLUME_PATH" || exit 1

# Mark directory as safe (avoids "dubious ownership" error)
git config --global --add safe.directory "$VOLUME_PATH"

# If this is the first time (no .git folder)
if [ ! -d ".git" ]; then
    echo "🚀 Initializing Git repo in $VOLUME_PATH"

    git init
    git branch -M "$BRANCH"

    # Configure git identity (per repo, so no global user setup needed)
    git config user.email "backup-bot@example.com"
    git config user.name "n8n Backup Bot"

    git remote add origin "https://${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"

    git add .
    git commit -m "Initial backup: $(date '+%Y-%m-%d %H:%M:%S')"

    # Ensure branch exists before pushing
    git push -u origin "$BRANCH" || git push -u origin HEAD:"$BRANCH"

else
    echo "🔄 Repository already initialized. Checking for changes..."

    git add .

    # Only commit if changes exist
    if ! git diff --cached --quiet; then
        git commit -m "Auto backup: $(date '+%Y-%m-%d %H:%M:%S')"
        git push origin "$BRANCH"
    else
        echo "✅ No changes to commit."
    fi
fi
