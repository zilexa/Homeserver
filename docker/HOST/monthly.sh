#!/bin/sh
# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Wait for other tasks to finish
while [[ -f ${SCRIPTDIR}/running-tasks ]] ; do
   sleep 10 ;
done


# Create monthly email body, add title and current date
# -----------------------------------------------------
install -b -m 750 /dev/null ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nMONTHLY HOUSEKEEPING TASKS\n" >> ${SCRIPTDIR}/logs/monthly.txt
date >> ${SCRIPTDIR}/logs/monthly.txt
printf "\n" >> ${SCRIPTDIR}/logs/monthly.txt


# CLEANUP - OS, local apps, user profile 
# --------------------------------------
echo -e "\nBLEACHBIT - Cleanup of OS, local apps and user profile..\n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp
bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp
# Add the summary of Bleachbit output to our monthly mail
tail -n 4 ${SCRIPTDIR}/logs/bleachbit.tmp >> ${SCRIPTDIR}/logs/monthly.txt
sudo rm ${SCRIPTDIR}/logs/bleachbit.tmp

# CLEANUP - unused docker images and volumes 
# ----------------------------------------
echo -e "\nCLEANUP of unused docker images..\n" >> ${SCRIPTDIR}/logs/monthly.txt
docker image prune -a -f |& tee -a ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nCLEANUP of unused docker volumes..\n" >> ${SCRIPTDIR}/logs/monthly.txt
docker volume prune -f |& tee -a ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nFor a full cleanup, remember to regularly run this command after verifying all your containers are running: docker system prune --all --volumes -f\n" >> ${SCRIPTDIR}/logs/monthly.txt

# Update docker images and recreate containers
# --------------------------------------------------------------
docker-compose pull && docker-compose up -d --remove-orphans


# Run btrfs scrub monthly
# -----------------------
echo -e "\n FILESTEM housekeeping.." >> ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nScrub btrfs filesystems..\n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdd |& tee -a ${SCRIPTDIR}/logs/monthly.txt

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
echo -e "\nRun BTRFS Balance using btrfs mail list recommendation (no longer necessary to perform this in steps) \n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=85 / |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=85 /mnt/drives/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=85 /mnt/drives/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# Update system
# -----------------------
# Query mirrors servers (on this continent only) to ensure updates are downloaded via the fastest HTTPS server
sudo pacman-mirrors --continent --api -P https >> ${SCRIPTDIR}/logs/monthly.txt
# Perform update, force refresh of update database files
pamac update --force-refresh --no-confirm >> ${SCRIPTDIR}/logs/monthly.txt


# Send email
# ---------------------------------
mail -s "Obelix Server - monthly housekeeping" default < ${SCRIPTDIR}/logs/monthly.txt

# Append email to monthly logfile and delete email
# ------------------------------------------------
touch ${SCRIPTDIR}/logs/monthly.log
sudo cat ${SCRIPTDIR}/logs/monthly.txt >> ${SCRIPTDIR}/logs/monthly.log
rm ${SCRIPTDIR}/logs/monthly.txt
