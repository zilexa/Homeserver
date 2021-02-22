#!/bin/sh
# Seperate config because btrbk requires sudo. 

# first wait for maintenance to finish
while [[ -f /tmp/maintenance-is-running ]] ; do
   sleep 10 ;
done


# first mount the backup drive
mount -U 17aa9385-fa24-4705-b6c0-f87d5d3f2fd5 /mnt/disks/backup1 -o subvolid=5,defaults,noatime,compress=zstd:3

# BACKUP OF LOCAL USERS
# ---------------------
# first use rsync to backup from MergerFS pool to backup drive
nocache rsync -azXA --progress --delete --inplace --numeric-ids --exclude '/mnt/pool/Users/Local/Asterix/TV' /mnt/pool/Users/Local/ /mnt/disks/backup1/users.backup/

# Create snapshots of synced users data
/usr/sbin/btrbk -c /home/asterix/docker/HOST/users-backup.conf -v run

# BACKUP OF SYSTEM
# ---------------------
# first mount btrfs-root filesystem
mount /dev/nvme0n1p2 /mnt/btrfs-root -o subvolid=5,defaults,noatime,compress=lzo 

# Create snaphots & backups of system drive and data Pool local users
/usr/sbin/btrbk -c /home/asterix/docker/HOST/system-backup.conf -v run

# Unmount btrfs root and backup drive
umount /mnt/disks/backup1
umount /mnt/btrfs-root
