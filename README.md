## 📝 n8n GitHub Sync Notes

### Prerequisites

* Docker + Git installed on the server.
* A running n8n container that uses a **Docker volume** (default: `n8n_data`).

  * The volume name can be:

    * `n8n_data` (default), or
    * a custom one you set when creating your container.
* A GitHub repository (private or public) where backups will be stored.

  * Repo name can be anything you choose (example: `n8n-backup`).
* A **GitHub Personal Access Token (PAT)** with at least `repo` permissions.

  * PAT = a token you generate from GitHub that replaces your password when using HTTPS.
  * Generate it here: **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)**.
* If your script requires `sudo` (for Docker volume access), configure **passwordless sudo** for your user.
  Add with `sudo visudo` (replace `youruser` with your actual Linux username):

  ```
  youruser ALL=(ALL) NOPASSWD: /home/youruser/n8n-github-sync/n8n-backup.sh
  ```

---

### Config inside the scripts

Update the values at the top of both scripts:

```
VOLUME_NAME="n8n_data"          # Docker volume name (adjust if different)
GITHUB_USERNAME="your-username" # Your GitHub username
GITHUB_REPO="your-repo-name"    # Repo you created for backups
GITHUB_PAT="ghp_xxxxxxxx"       # Your GitHub Personal Access Token (PAT)
BRANCH="main"                   # Branch to use in the repo
```

---

### Backup script (`n8n-backup.sh`)
``
* Finds the Docker volume path.
* If it’s the first run (no `.git`) → initializes repo, commits all data, pushes to GitHub.
* On later runs → commits only changes and pushes.

* Clone the scripts:

   ```
   git clone https://github.com/ongudidan/n8n-github-sync.git
   cd n8n-github-sync
   ```

Run manually:

```
./n8n-backup.sh
```

(or, if root access is required)

```
sudo ./n8n-backup.sh
```

---

### Restore script (`n8n-restore.sh`)

* Checks if the Docker volume exists → creates it if missing.
* If `.git` exists in the volume → stops to avoid overwriting.
* Otherwise:

  * Clones the GitHub backup repo into a temp folder.
  * Copies data into the volume.
  * Cleans up the temp folder.

Run manually:

```
./n8n-restore.sh
```

---

### Automating backup with cron

Edit your crontab:

```
crontab -e
```

Run backup **every minute**. You can use either:

**Option 1 (portable, works for most users):**

```
* * * * * sudo ~/n8n-github-sync/n8n-backup.sh >/dev/null 2>&1
```

**Option 2 (safer, always works if `~` isn’t expanded):**

```
* * * * * sudo /home/youruser/n8n-github-sync/n8n-backup.sh >/dev/null 2>&1
```

Replace `youruser` with your actual Linux username.

---

### What gets backed up

* The **contents of your n8n Docker volume** (workflows, credentials, execution history).
* **Not backed up**: environment variables like:

  ```
  -e WEBHOOK_URL=...
  -e VUE_APP_URL_BASE_API=...
  -e N8N_HOST=...
  -e N8N_PORT=...
  ```

  These must be set again when starting your container.

---

### Running n8n container

Example run command:

```
docker run -d \
  --restart=always \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_HOST=0.0.0.0 \
  -e N8N_PORT=5678 \
  -e WEBHOOK_URL=https://n8n.example.com/ \
  -e VUE_APP_URL_BASE_API=https://n8n.example.com/ \
  docker.n8n.io/n8nio/n8n
```

---

### Recovery on a new server

1. Install Docker + Git.
2. Clone the scripts:

   ```
   git clone https://github.com/ongudidan/n8n-github-sync.git
   cd n8n-github-sync
   ```
3. Edit `n8n-restore.sh` config with your volume name, repo, and PAT.
4. Run restore:

   ```
   ./n8n-restore.sh
   ```
5. Start the n8n container with your chosen run command (make sure env vars are set).

---
