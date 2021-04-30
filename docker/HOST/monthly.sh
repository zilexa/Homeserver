#!/bin/sh
# In other scripts, use this to check if nightly tasks are running and wait for it. 
#while [[ -f /tmp/backup-is-running ]] ; do
#   sleep 10 ;
#done
# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
#
# Create a temp file to indicate maintenance is running
touch ${SCRIPTDIR}/running-tasks


# Cleanup unused docker images and volumes
# ----------------------------------------
docker image prune -a -f
docker volume prune -f

# Check docker registry for image updates and send notifications
# --------------------------------------------------------------
diun


# Run btrfs scrub monthly
# -----------------------
btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2
btrfs scrub start -Bd -c 2 -n 4 /dev/nvme1n1
btrfs scrub start -Bd -c 2 -n 4 /dev/sdc
btrfs scrub start -Bd -c 2 -n 4 /dev/sdd
btrfs scrub start -Bd -c 2 -n 4 /dev/sdb

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
run_task btrfs balance start -dusage=10 /dev/nvme0n1p2
run_task btrfs balance start -v -dusage=20 /dev/nvme0n1p2
run_task btrfs balance start -dusage=10 /dev/nvme1n1
run_task btrfs balance start -v -dusage=20 /dev/nvme1n1
run_task btrfs balance start -dusage=10 /dev/sdc
run_task btrfs balance start -v -dusage=20 /dev/sdc
run_task btrfs balance start -dusage=10 /dev/sdd
run_task btrfs balance start -v -dusage=20 /dev/sdd
run_task btrfs balance start -dusage=10 /dev/sdb
run_task btrfs balance start -v -dusage=20 /dev/sdb

# Delete temp file, follow up tasks can continue
rm ${SCRIPTDIR}/running-tasks
