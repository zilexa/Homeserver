#!/bin/sh

# PREPARE
# -------
# Get this script folder path and the running user account
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
USERACCOUNT=$(who | head -n1 | cut -d " " -f1) 
# create tempfile to indicate nightly tasks are running
touch ${SCRIPTDIR}/running-tasks


# CLEANUP CACHE
# -------------
# User files >30d moved to data drives on pool-archive
#/usr/bin/bash ${SCRIPTDIR}/archiver.sh /mnt/drives/cache/users /mnt/pool-nocache/users 30


# FileRun - maintenance
# NOTE THIS IS ONLY REQUIRED IF YOU MODIFY/DELETE/CREATE FILES LOCALLY ON THE SERVER, OUTSIDE OF FILERUN OR WEBDAV!
# ---------------------
# Cleanup non-existing paths, cleanup >30 day old trash, index files created outside FileRun, read metadata  and generate thumbs of such files
# Do not run filerun as root. 
# su -l ${LOGUSER} -c '/usr/bin/bash ${SCRIPTDIR}/filerun.sh'


# SUBVOLUMES BACKUP  - use this section if your backup drives are HDDs to reduce number of spinups (by performing monthly maintenance immediately after creating backups)
# -----------------
/usr/bin/bash ${SCRIPTDIR}/btrbk/btrbk-mail.sh
## Perform monthtly maintenance on backup disk
#sudo run-if-today L zo && mount /mnt/drives/backup1
#sudo run-if-today L zo && sleep 10
## set the correct dev/sdX path for your backup1 drive
#sudo run-if-today L zo && btrfs scrub start -Bd -c 2 -n 4 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
#sudo run-if-today L zo && btrfs balance start -dusage=85 /mnt/drives/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
#sudo run-if-today L zo && btrfs balance start -v -dusage=85 /mnt/drives/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
#sudo run-if-today L zo && umount /mnt/drives/backup1

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
