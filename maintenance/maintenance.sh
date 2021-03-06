#!/bin/sh

# Create a temp file to indicate maintenance is running
touch /tmp/maintenance-is-running


# CLEANUP WATCHED TVSHOWS & MOVIES
# --------------------------------
# delete if watched x days ago
$HOME/docker/HOST/jellyfin-cleaner/media_cleaner.py >> $HOME/docker/HOST/logs/media_cleaner.log

# CLEANUP CACHE
# -------------
# files >30d moved to data drives on pool-archive
/usr/bin/bash $HOME/docker/HOST/cache_archiver.sh /mnt/disks/cache/Users /mnt/pool-archive/Users 30

# PROTECT DATA DRIVES - SnapRAID
# ------------------------------
# Run SnapRAID
snapraid-btrfs sync >> $HOME/docker/HOST/logs/snapraid-btrfs.log 2>&1
snapraid-btrfs cleanup


# Delete temp file, follow up tasks can continue
rm /tmp/maintenance-is-running
