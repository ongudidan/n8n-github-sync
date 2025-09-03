## 📝 n8n GitHub Sync Guide

### Prerequisites

* Docker + Git installed.
* n8n container already running with a **Docker volume** named `n8n_data`.
* GitHub PAT with `repo` access.
* Repo `n8n-backup` created in your GitHub account.
* Scripts cloned:

  ```
  git clone https://github.com/ongudidan/n8n-github-sync.git
  cd n8n-github-sync
  ```

---

### Config in both scripts

Edit these variables:

```
VOLUME_NAME="n8n_data"
GITHUB_USERNAME="ongudidan"
GITHUB_REPO="n8n-backup"
GITHUB_PAT="ghp_xxxxxxxx"   # replace with your PAT
BRANCH="main"
```

---

### Backup script (`n8n-backup.sh`)

* Finds `n8n_data` volume path.
* If no `.git` → initializes repo, commits everything, pushes.
* If `.git` exists → commits only changes and pushes.

Run manually:

```
./n8n-backup.sh
```

---

### Restore script (`n8n-restore.sh`)

* Checks if the volume exists → creates if missing.
* If `.git` exists inside → warns and stops.
* Otherwise:

  * Clones repo to a temp folder.
  * Copies data into the volume.
  * Cleans up.

Run manually:

```
./n8n-restore.sh
```

---

### Automating backup with cron

Edit crontab:

```
crontab -e
```

Run **every minute**:

```
* * * * * /home/youruser/n8n-github-sync/n8n-backup.sh >/dev/null 2>&1
```

If root access is required for Docker volumes:

```
* * * * * sudo /home/youruser/n8n-github-sync/n8n-backup.sh >/dev/null 2>&1
```

---

### What gets backed up

* The **volume contents** (workflows, executions, credentials).
* **Not backed up**: environment variables.

---

### n8n container run command

On a fresh server, restore the data, then run n8n like this:

```
docker run -d \
  --restart=always \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_HOST=0.0.0.0 \
  -e N8N_PORT=5678 \
  -e WEBHOOK_URL=https://n8n.fortunedevs.com/ \
  -e VUE_APP_URL_BASE_API=https://n8n.fortunedevs.com/ \
  docker.n8n.io/n8nio/n8n
```

---

### Recovery on a new server

1. Install Docker + Git.
2. Clone scripts:

   ```
   git clone https://github.com/ongudidan/n8n-github-sync.git
   cd n8n-github-sync
   ```
3. Edit `n8n-restore.sh` with your PAT.
4. Run restore:

   ```
   ./n8n-restore.sh
   ```
5. Start container with the command above.

---
