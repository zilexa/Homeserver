#!/bin/sh
# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Wait for other tasks to finish
while [[ -f ${SCRIPTDIR}/running-tasks ]] ; do
   sleep 10 ;
done

# Create monthly email body, add title and current date
# -----------------------------------------------------
touch ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\nMONTHLY HOUSEKEEPING TASKS\n" >> ${SCRIPTDIR}/logs/monthly.tmp
date >> ${SCRIPTDIR}/logs/monthly.tmp
printf "\n" >> ${SCRIPTDIR}/logs/monthly.tmp


# CLEANUP - OS, local apps, user profile 
# --------------------------------------
echo -e "\nBLEACHBIT - Cleanup of OS, local apps and user profile..\n" >> ${SCRIPTDIR}/logs/monthly.tmp
touch ${SCRIPTDIR}/logs/bleachbit.tmp
# Run bleachbit for root user to clean OS temp files
bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp
# Run Bleachbit for logged in user to clean files in $HOME
su -l ${LOGUSER} -c 'bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp'
# Add the summary of Bleachbit output to our monthly mail
tail -n 4 ${SCRIPTDIR}/logs/bleachbit.tmp >> ${SCRIPTDIR}/logs/monthly.tmp
rm ${SCRIPTDIR}/logs/bleachbit.tmp

# CLEANUP - unused docker images and volumes 
# ----------------------------------------
echo -e "\nCLEANUP of unused docker images..\n" >> ${SCRIPTDIR}/logs/monthly.tmp
docker image prune -a -f |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\nCLEANUP of unused docker volumes..\n" >> ${SCRIPTDIR}/logs/monthly.tmp
docker volume prune -f |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\nFor a full cleanup, remember to regularly run this command after verifying all your containers are running: docker system prune --all --volumes -f\n" >> ${SCRIPTDIR}/logs/monthly.tmp


# Pull new images + add notifications to email body (via Pullio) then update containers with new images and remove orphaned containers
# --------------------------------------------------------------
echo -e "\nDOCKER UPDATES\n" >> ${SCRIPTDIR}/logs/monthly.tmp
${SCRIPTDIR}/updater/pullio |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\nPull new images, recreate all containers, clean up orphans \n" >> ${SCRIPTDIR}/logs/monthly.tmp
docker-compose pull && docker-compose up -d --remove-orphans


# Run btrfs scrub monthly
# -----------------------
echo -e "\n FILESTEM housekeeping.." >> ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\nScrub btrfs filesystems..\n" >> ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/sda |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.tmp

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
echo -e "\nRun BTRFS Balance using btrfs mail list recommendation (no longer necessary to perform this in steps) \n" >> ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 / |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 /mnt/drives/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 /mnt/drives/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp


# Update system
# -----------------------
# Query mirrors servers (on this continent only) to ensure updates are downloaded via the fastest HTTPS server
pacman-mirrors --continent --api -P https >> ${SCRIPTDIR}/logs/monthly.tmp
# Perform update, force refresh of update database files
pamac update --force-refresh >> ${SCRIPTDIR}/logs/monthly.tmp
# Remove orphaned packages
pamac remove -o >> ${SCRIPTDIR}/logs/monthly.tmp
# Clean packages cache
pamac clean --keep 3 >> ${SCRIPTDIR}/logs/monthly.tmp


# Send email
# ---------------------------------
mail -s "Obelix Server - monthly housekeeping" default < ${SCRIPTDIR}/logs/monthly.tmp

# Append email to monthly logfile and delete email
# ------------------------------------------------
touch ${SCRIPTDIR}/logs/monthly.log # first time only
sudo cat ${SCRIPTDIR}/logs/monthly.tmp >> ${SCRIPTDIR}/logs/monthly.log
rm ${SCRIPTDIR}/logs/monthly.tmp
