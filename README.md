
# Paperless-ngx Backup Strategy for Synology NAS

This repository contains scripts and instructions for a robust backup strategy for a self-hosted [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) instance running via Docker Compose. The backups are stored on a Synology NAS.

## Backup Strategy Overview

The strategy backs up the three fundamental components of Paperless-ngx:

1.  **Documents:** All original and archived files from the `media` directory.
2.  **Database:** Metadata, tags, correspondents, etc., are backed up using the official exporter.
3.  **Configuration:** The `docker-compose.yml` and `.env` files, which are necessary for operation.

## Prerequisites

* A running Paperless-ngx instance on a Linux system (e.g., Ubuntu).
* The Paperless-ngx instance is managed with Docker Compose.
* A Synology NAS on the same network.
* `rsync` is installed on the Linux system (`sudo apt install rsync`).

## Step 1: Setup on the Synology NAS

1.  **Create a Shared Folder:**
    * Go to **Control Panel > Shared Folder**.
    * Create a new folder, e.g., `paperless_backup`.

2.  **Create a Dedicated Backup User:**
    * Go to **Control Panel > User & Group**.
    * Create a new user, e.g., `backup_user`.
    * Grant this user read/write permissions **only** for the `paperless_backup` folder.

3.  **Enable the rsync Service:**
    * Go to **Control Panel > File Services > rsync**.
    * Check the box for "Enable rsync service".

## Step 2: Configuration on the Paperless Server

1.  **Clone or Download the Repository:**
    Download the files from this repository to a directory on your Paperless server, e.g., `/opt/paperless-backup`.

    ```bash
    git clone [URL-OF-YOUR-GITHUB-REPO] /opt/paperless-backup
    cd /opt/paperless-backup
    ```

2.  **Customize the Configuration File:**
    * Copy the template `backup.env.template` to `backup.env`.
    * Open the `backup.env` file with a text editor (e.g., `nano backup.env`).
    * Enter all the required values for your environment (paths, NAS IP address, username). The comments in the file explain each variable.

3.  **Make the Script Executable:**
    Give the backup script the necessary execution permissions.

    ```bash
    chmod +x backup_paperless.sh
    ```

## Step 3: Run the Backup

You can run the backup manually at any time to test your configuration.

```bash
./backup_paperless.sh
```

 The script will now back up the three components (documents, database, configuration) to the corresponding subfolders on your Synology NAS.

## Step 4: Automation with a Cronjob
To run the backup regularly (e.g., daily at 2:00 AM), set up a cronjob.

Open the crontab table:

```bash

crontab -e
```
Add the following line to the end of the file. Adjust the path to the script accordingly.

Code-Snippet

```bash
# Run the Paperless-ngx backup every day at 2:00 AM
0 2 * * * /opt/paperless-backup/backup_paperless.sh > /var/log/paperless_backup.log 2>&1
```
This redirects the script's output to a log file, which helps with troubleshooting.

## Restore Procedure
A backup is only as good as its restorability. In an emergency, follow these steps:

1. Restore the Configuration: Copy the `docker-compose.yml` and .env files from your NAS backup back to the new server.

2. Restore the Documents: Copy the contents of the documents folder from the NAS back into the media folder of your new Paperless instance.

3. Import the Database:

Start the empty Paperless instance with docker compose up -d.

Copy the `paperless_export_...zip` from your NAS backup into the consume folder of your new instance.

Paperless-ngx will detect the export file and automatically start the import process. Monitor the logs with docker compose logs -f.
