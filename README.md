
# 📦 Paperless-NGX Backup Strategy

A reliable backup strategy is essential to protect your valuable documents and configurations in your self-hosted **Paperless-ngx** instance. This guide outlines a proven setup tailored for running on a local machine and backing up to a **Synology NAS** using `rsync` over SSH.

---

## 🛠️ Overview

This strategy includes three key components:

1. **Document Backup** (`media` folder)  
2. **Database Backup**  
3. **Configuration Backup**

All backups are pushed to a **Synology NAS** using `rsync`.

---

## 🧱 1. Prerequisites

### 🖥️ On Your Ubuntu (or Linux) Host

- Docker and Docker Compose installed  
- Paperless-NGX running locally  
- SSH access to your Synology NAS  
- A backup script (detailed below)  
- A `.env` file for environment configuration  

### 📦 On Your Synology NAS

1. **Create a Shared Folder**
   - Go to **Control Panel > Shared Folder**
   - Create a new folder (e.g., `paperless_backup`)

2. **Create a Dedicated Backup User**
   - Go to **Control Panel > User & Group**
   - Create a user (e.g., `backup_user`)  
   - Grant read/write access **only** to the shared folder

3. **Enable rsync Service**
   - Go to **Control Panel > File Services > rsync**
   - Enable **rsync service**

---

## ⚙️ 2. Environment Configuration

Create a `.env` file in the same directory as your backup script:

```env
# .env - Configuration for the Paperless-NGX Backup Script

# --- Local paths on your mini PC ---
PAPERLESS_MEDIA_DIR="/path/to/your/paperless/media"
PAPERLESS_COMPOSE_DIR="/path/to/your/docker-compose"
TEMP_BACKUP_DIR="/tmp/paperless_backup_temp"

# --- Synology NAS settings ---
NAS_USER="backup_user"
NAS_IP="IP_ADDRESS_OF_YOUR_NAS"
NAS_BASE_DIR="/volume1/paperless_backup"
```

---

## 📄 3. The Backup Script

Create a file `backup_paperless.sh` and make it executable:

```bash
chmod +x backup_paperless.sh
```

### Script: `backup_paperless.sh`

```bash
#!/bin/bash

# ==================================================
#          PAPERLESS-NGX BACKUP SCRIPT
#      (loads configuration from .env)
# ==================================================

# Load environment variables
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}/.env"

# Validate required variables
if [ -z "$PAPERLESS_MEDIA_DIR" ] || [ -z "$NAS_IP" ]; then
    echo "Error: Required variables are not set in .env. Please check the file."
    exit 1
fi

echo "=========================================="
echo "Paperless-ngx backup started on $(date)"
echo "=========================================="

# --- 1. Backup Documents ---
echo "--> [1/3] Backing up documents..."
rsync -avz --delete "$PAPERLESS_MEDIA_DIR/" "$NAS_USER@$NAS_IP:$NAS_BASE_DIR/documents/"
echo "    ...Documents successfully backed up."

# --- 2. Backup Database ---
echo "--> [2/3] Backing up database..."
mkdir -p "$TEMP_BACKUP_DIR"
cd "$PAPERLESS_COMPOSE_DIR" || exit 1
docker compose exec -T webserver document_exporter ../data/ --zip
EXPORT_FILE=$(find "$PAPERLESS_COMPOSE_DIR/data/" -name "*.zip")
mv "$EXPORT_FILE" "$TEMP_BACKUP_DIR/paperless_export_$(date +%F).zip"
rsync -avz --remove-source-files "$TEMP_BACKUP_DIR/" "$NAS_USER@$NAS_IP:$NAS_BASE_DIR/database/"
echo "    ...Database successfully backed up."

# --- 3. Backup Configuration ---
echo "--> [3/3] Backing up configuration..."
rsync -avz "$PAPERLESS_COMPOSE_DIR/" --include="docker-compose.yml" --include=".env" --exclude="*" "$NAS_USER@$NAS_IP:$NAS_BASE_DIR/config/"
echo "    ...Configuration successfully backed up."

echo "=========================================="
echo "Backup completed successfully."
echo "=========================================="
```

---

## 🔁 4. Automation with Cron

To run the backup script automatically (e.g., daily at 2:00 AM):

### Edit the Crontab

```bash
crontab -e
```

### Add This Line

```bash
0 2 * * * /path/to/your/backup_paperless.sh > /var/log/paperless_backup.log 2>&1
```

> This logs output to `/var/log/paperless_backup.log` and runs daily at 2 AM.

---

## ✅ Result

After setup:

- Your **documents**, **database**, and **configuration** are backed up daily  
- Data is stored safely on your **Synology NAS**  
- Deleted files in `media/` are removed from the NAS (mirrored state)

---

## 📌 Optional: Google Drive Upload (Advanced)

You can extend the script to also upload backups to Google Drive using tools like:

- [`rclone`](https://rclone.org/)
- Google Drive API with automation

Let me know if you'd like help automating that.

---

## 📂 Folder Structure on NAS

```
/volume1/paperless_backup/
├── documents/        # Synced media files
├── database/         # Database dumps (zip)
└── config/           # docker-compose.yml and .env
```

---

## 🧪 Test Your Backup

- Manually run the script once to validate setup  
- Occasionally restore test files to verify backup integrity  
