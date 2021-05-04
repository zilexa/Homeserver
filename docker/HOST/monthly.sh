#!/bin/sh
# In other scripts, use this to check if nightly tasks are running and wait for it. 
#while [[ -f /tmp/backup-is-running ]] ; do
#   sleep 10 ;
#done
# Create a temp file to indicate maintenance is running
touch ${SCRIPTDIR}/running-tasks
# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"


# Create email body, add current date
# -----------------------------------
install -b -m 750 /dev/null ${SCRIPTDIR}logs/monthly.txt
echo "$now" >> ${SCRIPTDIR}/logs/monthly.txt


# CLEANUP - OS, local apps, user profile 
# --------------------------------------
sudo bleachbit --preset --clean
# Keep only the summary (last 4 lines) of Bleachbit output in email file
tail -n 4 ${SCRIPTDIR}/logs/monthly.txt > ${SCRIPTDIR}/logs/monthly.tmp
mv -f ${SCRIPTDIR}/logs/monthly.tmp ${SCRIPTDIR}/logs/monthly.txt
# Add a header to this output
sed -i '1iCLEANUP of OS, local apps and user profile..\n' ${SCRIPTDIR}/logs/monthly.txt

# CLEANUP - unused docker images and volumes 
# ----------------------------------------
echo -e "\nCLEANUP unused docker images..\n" >> ${SCRIPTDIR}/logs/monthly.txt
docker image prune -a -f |& tee -a ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nCLEANUP unused docker volumes..\n" >> ${SCRIPTDIR}/logs/monthly.txt
docker volume prune -f |& tee -a ${SCRIPTDIR}/logs/monthly.txt
echo -e "\nFor a full cleanup, remember to regularly run this command after verifying all your containers are running: docker system prune --all --volumes -f\n" >> ${SCRIPTDIR}/logs/monthly.txt

# Check Docker registry for image updates and send notifications
# --------------------------------------------------------------
diun


# Run btrfs scrub monthly
# -----------------------
echo -e "\nScrub btrfs filesystems..\n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/nvme1n1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdd |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs scrub start -Bd -c 2 -n 4 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.txt

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
echo -e "\nBalance btrfs filesystems in 2 runs each.. \n" >> ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /dev/nvme1n1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /dev/nvme1n1 |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /dev/sdd |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /dev/sdd |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -dusage=10 -musage=5 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.txt
sudo btrfs balance start -v -dusage=20 -musage=10 /dev/sdb |& tee -a ${SCRIPTDIR}/logs/monthly.txt


# Send email
# ---------------------------------
s-nail -s "Obelix monthly tasks" < $HOME/docker/HOST/logs/monthly.txt default


# Append email to monthly logfile and delete email
# ------------------------------------------------
touch ${SCRIPTDIR}/logs/monthly.log
sudo cat ${SCRIPTDIR}/logs/monthly.txt >> ${SCRIPTDIR}/logs/monthly.log
rm ${SCRIPTDIR}/logs/monthly.txt


# Delete temp file, follow up tasks can continue
rm ${SCRIPTDIR}/running-tasks
