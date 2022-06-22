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
# delete if watched (configure by running the command yourself first)
python3 ${SCRIPTDIR}/media-cleaner/media_cleaner.py |& tee -a ${SCRIPTDIR}/logs/media_cleaner.log


# CLEANUP CACHE
# -------------
# User files >30d moved to data drives on pool-archive
#/usr/bin/bash ${SCRIPTDIR}/archiver.sh /mnt/disks/cache/Users /mnt/pool-nocache/Users 30


# FileRun 
# -------
# Empty trash >30 days old files
docker exec -u ${USER} -w /var/www/html/cron filerun php empty_trash.php -days 30
# Clear db of files/folders that no longer exist
docker exec -u ${USER} -w /var/www/html/cron filerun php paths_cleanup.php --deep
# Index filenames for files created outside FileRun
docker exec -u ${USER} -w /var/www/html/cron filerun php index_filenames.php /user-files true
# Read metadata of files created outside FileRun, the UI adjusts to photos (GPS), videos etc and has specific options per filetype
docker exec -u ${USER} -w /var/www/html/cron filerun php metadata_index.php 
# Create thumbnails for files - allows instant scrolling through photos
docker exec -u ${USER} -w /var/www/html/cron filerun php make_thumbs.php
# Create previews for files - allows instant previews for photos
docker exec -u ${USER} -w /var/www/html/cron filerun php make_thumbs.php --username FiLeRuNuSeR1 --size large
docker exec -u ${USER} -w /var/www/html/cron filerun php make_thumbs.php --username FiLeRuNuSeR2 --size large
docker exec -u ${USER} -w /var/www/html/cron filerun php make_thumbs.php --username FiLeRuNuSeR3 --size large
docker exec -u ${USER} -w /var/www/html/cron filerun php make_thumbs.php --username FiLeRuNuSeR4 --size large
# Index content of files, extracting text, to allow searching within files - not recommended
# usr/bin/docker exec -u ${USERACCOUNT} -w /var/www/html/cron -it filerun php process_search_index_queue.php


# SUBVOLUMES BACKUP  
# -----------------
# Create snapshots and send snapshots to backup locations, then email a summary. 
/usr/bin/bash ${SCRIPTDIR}/btrbk/btrbk-mail.sh

# Now that backup drives are spinning, perform monthtly maintenance on backup disk
# run the following commands for each local backup drive:
sudo run-if-today L zo && mount /mnt/disks/backup1
sudo run-if-today L zo && sleep 10
sudo run-if-today L zo && btrfs balance start -dusage=10 -musage=5 /mnt/disks/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo run-if-today L zo && btrfs balance start -v -dusage=20 -musage=10 /mnt/disks/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo run-if-today L zo && btrfs scrub start -Bd -c 2 -n 4 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# S.M.A.R.T. disk health scan on ALL disks (now that Backup1 is still spinning)
# ----------------------
mount /mnt/disks/backup1
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
