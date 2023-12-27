#!/bin/sh
# Get this script folder path
SCRIPTDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Wait for backup task to finish
#while [[ -f /var/lock/btrbk.lock ]] ; do
#   sleep 10 ;
#done
# Wait for Nightly task to finish - btrbk doesn't delete its lockfile due to a bug so we need this. btrbk-mail.sh wil create this file:
while [[ -f ${SCRIPTDIR}/running-tasks ]] ; do
   sleep 10 ;
done


# Create monthly email body, add title and current date
# -----------------------------------------------------
touch ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\n_____MONTHLY HOUSEKEEPING TASKS_____" > ${SCRIPTDIR}/logs/monthly.tmp


# CLEANUP - OS, local apps, user profile 
# --------------------------------------
echo -e "\n____________SYSTEM CLEANUP____________\n" >> ${SCRIPTDIR}/logs/monthly.tmp

# Run bleachbit for root user to clean OS temp files
touch ${SCRIPTDIR}/logs/bleachbit.tmp
bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp
# Add the summary of Bleachbit output to our monthly mail
echo -e "\nBLEACHBIT - system wide cleanup of OS and local applications..\n" >> ${SCRIPTDIR}/logs/monthly.tmp
tail -n 4 ${SCRIPTDIR}/logs/bleachbit.tmp >> ${SCRIPTDIR}/logs/monthly.tmp
rm ${SCRIPTDIR}/logs/bleachbit.tmp

# Run Bleachbit for regular user to clean files in $HOME. # REMOVED, WILL BE REPLACED WITH RECOMMENDATIONS FROM ARCH WIKI.
#su -l ${LOGUSER} -c 'touch ${SCRIPTDIR}/logs/bleachbit.tmp'
#su -l ${LOGUSER} -c 'bleachbit --preset --clean |& tee -a ${SCRIPTDIR}/logs/bleachbit.tmp'
# Add the summary of Bleachbit output to our monthly mail
#echo -e "\nBLEACHBIT - user level cleanup (/home folder).. \n" >> ${SCRIPTDIR}/logs/monthly.tmp
#tail -n 4 ${SCRIPTDIR}/logs/bleachbit.tmp >> ${SCRIPTDIR}/logs/monthly.tmp
#rm ${SCRIPTDIR}/logs/bleachbit.tmp


# DOCKER - CLEANUP
# ----------------------------------------
echo -e "\n____________DOCKER CLEANUP____________\n" >> ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\n CLEANUP Remove all unused containers, networks and dangling or unreferenced images and volumes: \n" >> ${SCRIPTDIR}/logs/monthly.tmp
docker system prune --all --volumes -f |& tee >(tail -n 1 >> ${SCRIPTDIR}/logs/monthly.tmp)

# DOCKER - UPDATES
echo -e "\n____________DOCKER UPDATES____________\n" >> ${SCRIPTDIR}/logs/monthly.tmp
# --------------------------------------------------------------
# Get latest images
su -l ${LOGUSER} -c 'docker-compose pull'

# Get list of newly downloaded images, to provide info about which have been updated:
runningImages=$(docker ps -a --format "< {{.Image}} >" && docker ps -a --format "< {{.Image}}:latest >") # Latter command is to include images without any tags determined
if [ -z "$runningImages" ]; then # Necessary when no container is running
    runningImages="< >"
fi
updatedImages=$(docker images --format 'table {{.Repository}}\t{{.CreatedAt}}>\t< {{.ID}} >\t' | grep -v "$runningImages")
echo -e "\nUPDATED the following docker images: \n" >> ${SCRIPTDIR}/logs/monthly.tmp
echo "$updatedImages" | awk '{print $1,$2}' | cut -d/ -f2- | column -t >> ${SCRIPTDIR}/logs/monthly.tmp

# Now update the services by recreating the containers based on the newly downloaded images. 
su -l ${LOGUSER} -c 'docker-compose up -d --remove-orphans' # not adding to email body as it would be a lot
echo -e "\nDocker updates finished. \n" >> ${SCRIPTDIR}/logs/monthly.tmp


# Run btrfs scrub monthly
# -----------------------
echo -e "\n____________FILESTYSTEMS____________\n" >> ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\n FILESTEM housekeeping.." >> ${SCRIPTDIR}/logs/monthly.tmp
echo -e "\nScrub btrfs filesystems..\n" >> ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/nvme0n1p2 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/sda1 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/sdc |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
mount /mnt/drives/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs scrub start -Bd -c 2 -n 4 /dev/sdb1 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp

# Run btrfs balance monthly, first 10% data, then try 20%
# -------------------------
echo -e "\nRun BTRFS Balance using btrfs mail list recommendation\n" >> ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 / |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 /mnt/drives/data0 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 /mnt/drives/data1 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp
btrfs balance start -dusage=85 /mnt/drives/backup1 |& tee -a ${SCRIPTDIR}/logs/monthly.tmp


# Storage Status Report
# -----------------------------------------------------
echo -e "\n\n_________STORAGE STATUS REPORT________" > /tmp/storagereport.tmp
echo -e "\n               ~~~ STORAGE PER USER ~~~" >> /tmp/storagereport.tmp
sudo btrfs filesystem du -s /mnt/pool/users/* >> /tmp/storagereport.tmp
echo -e "\n                ~~~ USERS filesystem ~~~" >> /tmp/storagereport.tmp
sudo btrfs fi usage /mnt/pool/users | grep 'Free (estimated)' >> /tmp/storagereport.tmp
sudo df -h /dev/sda1 >> /tmp/storagereport.tmp
echo -e "\n                ~~~ MEDIA filesystem ~~~" >> /tmp/storagereport.tmp
sudo btrfs fi usage /mnt/pool/media | grep 'Free (estimated)' >> /tmp/storagereport.tmp
sudo df -h /dev/sdc >> /tmp/storagereport.tmp
echo -e "\n               ~~~ BACKUPS filesystem ~~~" >> /tmp/storagereport.tmp
sudo btrfs fi usage /mnt/pool/backup1 | grep 'Free (estimated)' >> /tmp/storagereport.tmp
sudo df -h /dev/sdb1 >> /tmp/storagereport.tmp
umount /mnt/drives/backup1 |& tee -a /tmp/storagereport.tmp
echo -e "\n                   ~~~ OS filesystem ~~~" >> /tmp/storagereport.tmp
sudo btrfs fi usage / | grep 'Free (estimated)' >> /tmp/storagereport.tmp
sudo df -h /dev/nvme0n1p2 >> /tmp/storagereport.tmp


# Update system
# -----------------------
echo -e "\n____________SYSTEM UPDATE____________\n" >> ${SCRIPTDIR}/logs/monthly.tmp
# Query mirrors servers (on this continent only) to ensure updates are downloaded via the fastest HTTPS server
pacman-mirrors --continent --api -P https
# Perform update, force refresh of update database files
pamac update --force-refresh --no-confirm
# Clean packages cache
pamac clean --keep 3 --no-confirm >> ${SCRIPTDIR}/logs/monthly.tmp
# Check if a restart is needed, add this notification to the top of the email
echo -n "OBELIX MOHTHLY STATUS REPORT - " > /tmp/monthlymail.tmp
date >> /tmp/monthlymail.tmp
needrestart >> /tmp/monthlymail.tmp


# Send email - to all users in the household (alias: asterix instead of default)
# ---------------------------------
cat /tmp/storagereport.tmp >> /tmp/monthlymail.tmp
rm /tmp/storagereport.tmp
cat ${SCRIPTDIR}/logs/monthly.tmp >> /tmp/monthlymail.tmp
mail -s "Obelix server - monthly report" asterix < /tmp/monthlymail.tmp
rm /tmp/monthlymail.tmp
# Delete old monthly file. 
rm ${SCRIPTDIR}/logs/monthly.tmp
