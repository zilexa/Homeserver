#!/bin/sh

# PREPARE
# -------
# Get this script folder path and the running user account
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
USERACCOUNT=$(who | head -n1 | cut -d " " -f1) 
# create tempfile to indicate nightly tasks are running
touch ${SCRIPTDIR}/running-tasks


# CLEANUP WATCHED TVSHOWS & MOVIES
# --------------------------------
# delete if watched x days ago
python3 ${SCRIPTDIR}/mediacleaner/media_cleaner.py |& tee -a ${SCRIPTDIR}/logs/media_cleaner.log


# CLEANUP CACHE
# -------------
# User files >30d moved to data drives on pool-archive
#/usr/bin/bash ${SCRIPTDIR}/archiver.sh /mnt/disks/cache/Users /mnt/pool-nocache/Users 30


# FileRun 
# -------
# Empty trash >30 days old files
docker exec -w /var/www/html/cron filerun php empty_trash.php -days 30
# Clear db of files/folders that no longer exist
docker exec -w /var/www/html/cron filerun php paths_cleanup.php --deep
# Index filenames for files created outside FileRun
docker exec -w /var/www/html/cron filerun php index_filenames.php /user-files true
# Read metadata of files created outside FileRun, the UI adjusts to photos (GPS), videos etc and has specific options per filetype
docker exec -w /var/www/html/cron filerun php metadata_index.php 
# Create thumbnails for files
docker exec -w /var/www/html/cron filerun php make_thumbs.php
# Create large thumbnails (previews) for files - this task only works per-user
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username USERNAME1 --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username USERNAME2 --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username USERNAME3 --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username USERNAME4 --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username USERNAME5 --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username USERNAME5 --size large
# Index content of files, extracting text, to allow searching within files - not recommended
# usr/bin/docker exec -w /var/www/html/cron -it filerun php process_search_index_queue.php


# SUBVOLUMES BACKUP  
# -----------------
/usr/bin/bash ${SCRIPTDIR}/btrbk/btrbk-mail.sh
# Perform monthtly maintenance on backup disk
sudo run-if-today L zo && mount /mnt/drives/backup1
sudo run-if-today L zo && sleep 10
# set the correct dev/sdX path for your backup1 drive
sudo run-if-today L zo && btrfs scrub start -Bd -c 2 -n 4 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo run-if-today L zo && btrfs balance start -dusage=10 -musage=5 /mnt/drives/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo run-if-today L zo && btrfs balance start -v -dusage=20 -musage=10 /mnt/drives/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# Only if you still use Scrutiny
# S.M.A.R.T. disk health scan on ALL disks (now that Backup1 is still spinning)
# ----------------------
#mount /mnt/drives/backup1
#sleep 10
#docker exec scrutiny /app/scrutiny-collector-metrics run
#sleep 10
#umount /mnt/disks/backup1


# PARITY-BASED BACKUP (now that Parity1 is still spinning)
# -------------------
#python3 ${SCRIPTDIR}/snapraid/snapraid-btrfs-runner.py -c ${SCRIPTDIR}/snapraid/snapraid-btrfs-runner.conf
#sleep 10
#umount /mnt/disks/parity1


# Delete temp file, follow up tasks can continue
rm ${SCRIPTDIR}/running-tasks
