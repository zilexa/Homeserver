#!/bin/sh
# btrbk requires sudo, schedule via command: sudo crontab -e 

# Make sure maintenance is finished
while [[ -f /tmp/maintenance-is-running ]] ; do
   sleep 10 ;
done

# Mount systemdrive btrfs-root and the backup disk
mount /dev/nvme0n1p2 /mnt/system-root -o subvolid=5,defaults,noatime,compress=lzo 
mount -U !!!UUID OF BACKUPDRIVE HERE!!! /mnt/disks/backup1 -o defaults,noatime,compress=zstd:8

# Run backups
/usr/sbin/btrbk -c /home/$SUDO_USER/docker/HOST/backup.conf -v run

# Unmount btrfs root and backup drive
umount /mnt/disks/backup1
umount /mnt/btrfs-root
