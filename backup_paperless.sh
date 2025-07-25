#!/bin/bash

# ==================================================
#          PAPERLESS-NGX BACKUP SCRIPT
#      (loads configuration from .env)
# ==================================================

# Load the configuration from the .env file in the same directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "${SCRIPT_DIR}/.env"

# Check if important variables are set
if [ -z "$PAPERLESS_MEDIA_DIR" ] || [ -z "$NAS_IP" ]; then
    echo "Error: Important variables are not set in .env. Please check the file."
    exit 1
fi

# --- Script Logic ---
echo "=========================================="
echo "Paperless-ngx backup started on $(date)"
echo "=========================================="

# 1. Backup documents

echo "--> [1/3] Backing up documents..."
echo "rsync: A fast and versatile file-copying tool used for backups and mirroring."
echo "-a: Archive mode – preserves symbolic links, permissions, timestamps, and recursive copy."
echo "-v: Verbose – shows detailed output of what's being copied."
echo "-z: Compression – compresses file data during the transfer to save bandwidth."
echo "--delete: Deletes files in the destination directory that no longer exist in the source. This ensures the destination is an exact mirror of the source."

rsync -avz --delete "$PAPERLESS_MEDIA_DIR/" "$NAS_USER@$NAS_IP:$NAS_BASE_DIR/documents/"
echo "    ...Documents successfully backed up."

# 2. Backup database
echo "--> [2/3] Backing up database..."
mkdir -p "$TEMP_BACKUP_DIR"
cd "$PAPERLESS_COMPOSE_DIR" || exit 1
docker compose exec -T webserver document_exporter ../data/ --zip
EXPORT_FILE=$(find "$PAPERLESS_COMPOSE_DIR/data/" -name "*.zip")
mv "$EXPORT_FILE" "$TEMP_BACKUP_DIR/paperless_export_$(date +%F).zip"
rsync -avz --remove-source-files "$TEMP_BACKUP_DIR/" "$NAS_USER@$NAS_IP:$NAS_BASE_DIR/database/"
echo "    ...Database successfully backed up."

# 3. Backup configuration
echo "--> [3/3] Backing up configuration..."
rsync -avz "$PAPERLESS_COMPOSE_DIR/" --include="docker-compose.yml" --include=".env" --exclude="*" "$NAS_USER@$NAS_IP:$NAS_BASE_DIR/config/"
echo "    ...Configuration successfully backed up."

echo "=========================================="
echo "Backup completed successfully."
echo "=========================================="