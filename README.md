# 📤 BACKUP: Save n8n data to GitHub

1. **Install Git** (Docker is already installed and running for backup)

```bash
sudo apt update
sudo apt install -y git
```

2. **Create a GitHub repo + PAT**

* Create a repo (example: `n8n-backup`)
* Create a **Personal Access Token (PAT)** with at least **repo** permission:  
  GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic).

3. **Clone the helper scripts**

```bash
cd ~
git clone https://github.com/ongudidan/n8n-github-sync.git
cd n8n-github-sync
```

4. **Make scripts executable**

```bash
chmod +x n8n-backup.sh
chmod +x n8n-restore.sh
```

5. **Configure the backup script**

```bash
nano n8n-backup.sh
```

Edit:

```bash
VOLUME_NAME="n8n_data"          # Docker volume name (adjust if different)
GITHUB_USERNAME="your-username" # Your GitHub username
GITHUB_REPO="your-repo-name"    # Repo you created for backups
GITHUB_PAT="ghp_xxxxxxxx"       # Your GitHub Personal Access Token (PAT)
BRANCH="main"                   # Branch to restore from
```

Save and exit.

6. **Allow backup script to run without password (optional but recommended)**
   Open sudoers file:

```bash
sudo visudo
```

Add this line (replace `youruser` and the repo path):

```
youruser ALL=(ALL) NOPASSWD: /home/youruser/n8n-github-sync/n8n-backup.sh
```

7. **Run a manual backup**

```bash
sudo ./n8n-backup.sh
```

8. **Automate backups with cron (optional)**

```bash
crontab -e
```

Add:

```
* * * * * sudo /home/youruser/n8n-github-sync/n8n-backup.sh >/dev/null 2>&1
```

---

# 📥 RESTORE: Recover n8n data from GitHub

1. **Install Docker and Git** (needed here if restoring on a fresh server)

```bash
sudo apt update
sudo apt install -y docker.io git
```

2. **Clone the helper scripts**

```bash
cd ~
git clone https://github.com/ongudidan/n8n-github-sync.git
cd n8n-github-sync
```

3. **Make scripts executable**

```bash
chmod +x n8n-backup.sh
chmod +x n8n-restore.sh
```

4. **Configure the restore script**

```bash
nano n8n-restore.sh
```

Edit:

```bash
VOLUME_NAME="n8n_data"          # Docker volume name (adjust if different)
GITHUB_USERNAME="your-username" # Your GitHub username
GITHUB_REPO="your-repo-name"    # Repo you created for backups
GITHUB_PAT="ghp_xxxxxxxx"       # Your GitHub Personal Access Token (PAT)
BRANCH="main"                   # Branch to restore from
```

Save and exit.

5. **Stop the running n8n container (if any)**

```bash
docker ps
docker stop n8n   # replace with your container name
```

6. **Run restore**

```bash
sudo ./n8n-restore.sh
```

7. **Restart or re-create n8n container**

```bash
docker run -d \
  --restart=always \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_HOST=0.0.0.0 \
  -e N8N_PORT=5678 \
  -e WEBHOOK_URL=https://n8n.example.com/ \
  -e VUE_APP_URL_BASE_API=https://n8n.example.com/ \
  --name n8n \
  docker.n8n.io/n8nio/n8n
```

---

👉 This way:

* **Backup** assumes Docker is already running, only installs `git`.
* **Restore** assumes a fresh server (installs both `docker.io` + `git`).
* **visudo step** only appears in backup, for cron automation.

---
