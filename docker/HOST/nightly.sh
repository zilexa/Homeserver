#!/bin/sh
# In other scripts, use this to check if nightly tasks are running and wait for it. 
#while [[ -f /tmp/backup-is-running ]] ; do
#   sleep 10 ;
#done

# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Create a temp file to indicate maintenance is running
touch ${SCRIPTDIR}/running-tasks


# CLEANUP WATCHED TVSHOWS & MOVIES
# --------------------------------
# delete if watched x days ago
${SCRIPTDIR}/media-cleaner/media_cleaner.py >> ${SCRIPTDIR}/logs/media_cleaner.log


# CLEANUP CACHE
# -------------
# User files >30d moved to data drives on pool-archive
#/usr/bin/bash ${SCRIPTDIR}/archiver.sh /mnt/disks/cache/Users /mnt/pool-nocache/Users 30


# FileRun 
# -------
# Empty trash >30 days old files
docker exec -w /var/www/html/cron -it filerun php empty_trash.php -days 30
# Clear db of files/folders that no longer exist
docker exec -w /var/www/html/cron -it filerun php paths_cleanup.php --deep
# Index filenames for files created outside FileRun
docker exec -w /var/www/html/cron -it filerun php index_filenames.php /user-files true
# Read metadata of files created outside FileRun, the UI adjusts to photos (GPS), videos etc and has specific options per filetype
docker exec -w /var/www/html/cron -it filerun php metadata_index.php
# Create thumbnails for photos - allows instant scrolling through photos
docker exec -w /var/www/html/cron -it filerun php make_thumbs.php
# Index content of files, extracting text, to allow searching within files - not recommended
# usr/bin/docker exec -w /var/www/html/cron -it filerun php process_search_index_queue.php


# SUBVOLUMES BACKUP  
# -----------------
/usr/bin/bash ${SCRIPTDIR}/btrbk/btrbk-mail.sh
# Perform monthtly maintenance on backup disk
sudo run-if-today L Sun && mount /mnt/disks/backup1
sudo run-if-today L Sun && sleep 10
sudo run-if-today L Sun && btrfs balance start -dusage=10 -musage=5 /mnt/disks/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo run-if-today L Sun && btrfs balance start -v -dusage=20 -musage=10 /mnt/disks/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo run-if-today L Sun && btrfs scrub start -Bd -c 2 -n 4 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# S.M.A.R.T. disk health scan on ALL disks (now that Backup1 is still spinning)
# --------------------------
mount /mnt/disks/parity1
sleep 10
docker exec scrutiny /app/scrutiny-collector-metrics run
sleep 10
umount /mnt/disks/backup1


# PARITY-BASED BACKUP (now that Parity1 is still spinning)
# -------------------
python3 ${SCRIPTDIR}/snapraid/snapraid-btrfs-runner.py -c ${SCRIPTDIR}/snapraid/snapraid-btrfs-runner.conf
sleep 10
umount /mnt/disks/parity1


# Delete temp file, follow up tasks can continue
rm ${SCRIPTDIR}/running-tasks
