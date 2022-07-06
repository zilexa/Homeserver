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


# Check docker registry for image updates and send notifications
# --------------------------------------------------------------
${SCRIPTDIR}/updater/diun
echo -e "\nDOCKER UPDATES - See DIUN email\n" >> ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nAuto-updating images pullio label.. \n" >> ${SCRIPTDIR}/logs/monthly.txt
pullio  |& tee -a ${SCRIPTDIR}/logs/monthly.txt

# Run btrfs scrub monthly
# -----------------------
echo -e "\n FILESTEM housekeeping.." >> ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nScrub btrfs filesystems..\n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sda |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.txt

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
echo -e "\nBalance btrfs filesystems in 2 runs each.. \n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 / |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 / |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /mnt/drives/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /mnt/drives/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /mnt/drives/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /mnt/drives/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# Send email
# ---------------------------------
mail -s "Obelix Server - monthly housekeeping" default < /home/asterix/docker/HOST/logs/monthly.txt


# Append email to monthly logfile and delete email
# ------------------------------------------------
sudo cat ${SCRIPTDIR}/logs/monthly.txt >> ${SCRIPTDIR}/logs/monthly.log
rm ${SCRIPTDIR}/logs/monthly.txt
