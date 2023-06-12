Contents: 
  1. [Timeline backups & Offline archiving](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/backupstrategy.md#2-timeline-backups)
  2. [(Optional) parity-based backup](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/backupstrategy.md#1-disk-protection)
  3. [Replacing disks, restoring data](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/backupstrategy.md#4-replacing-disks-restoring-data)


### 1. Timeline backups & offline archiving
[btrbk](https://digint.ch/btrbk) is thede-facto tool for backups of BTRFS subvolumes. It uses BTRFS native filesystem-level data replication and snapshot features. This means it is extremely fast and reliable. It supports everything from scheduled snapshotting, backing up to local or networked locations and archiving to local, networked or USB drives. 
- The btrbk.conf file contains 1) the subvolumes you want to snapshot 2) the location of the snapshots on the same drive and 3) (optional) the location of the backup drive. Besides that, it contains your retention policy for snapshots, backups and archives. 
- You will end up with a folder on your drives that contain timeline-like snapshots and a similar folder on your backup drive. 
- Periodically, you can connect a USB drive (see [Step 2 here](https://github.com/zilexa/Homeserver/tree/master/filesystem#step-21-prepare-drives) on how to prep the drive, including step 2.4) to archive your internal backup drive to the USB drive. 
- For a short intro into btrbk, [read this](https://wiki.gentoo.org/wiki/Btrbk). 


### 2. Parity-based backup 
With SnapRAID, you can dedicate 1 or multiple drives to store a parity file. With 1 parity drive, you can protect up to 4 drives against a single drive failure. This makes it a very economic solution to protect multiple drives against drive failure without actually having a backup drive for each drive you want to protect. You can also add multiple parity drives.  
SnapRAID updates the parity on a set schedule. For example, daily or every X hours.
With SnapRAID-BTRFS (a wrapper for SnapRAID), the SnapRAID uses a snapshot of your subvolumes to create/update the parity file. Now, the live subvolumes data can be modified between updates, you will always be able to restore the last snapshot of the drive. 
With SnapRAID-BTRFS-Runner, you will get email notifications of the SnapRAID sync updates. 
- LIMITAION: you can only configure 1 subvolume per disk. If you store /Media and /Users on the same disk, the logical choice would be to protect /Users with SnapRAID. 
- If you plan to use SnapRAID, use it for your Users subvolumes or for the Media subvolumes (Movies, Shows, Music, Books) but not for the `incoming` folder, as that folders content change a lot, your snapshots will take up lots of space. 


### 3. Replacing disks, restoring data
- btrfs has its own `replace` command that should be used to replace disks, unless the disk has failed. 
- In case of disk failure:  insert a replacement disk and restore the data ([Snapraid manual section 4.4](https://www.snapraid.it/manual)) on it easily via snapraid. You can also use snapraid to restore individual files ([Snapraid manual section 4.3](https://www.snapraid.it/manual)) Use `snapraid-btrfs fix` instead of `snapraid fix` ([read here](https://github.com/automorphism88/snapraid-btrfs#q-can-i-restore-a-previous-snapshot)) unless your last sync was done via the latter.  
- To access all the disks timeline backups in 1 overview: create a MergerFS mount point (`/mnt/pool-backup`) combining `/mnt/disks/backup1/cache.users`, `/mnt/disks/backup1/data1.users`, `/mnt/disks/backup1/data2.users` to have a single Users folder in `mnt/pool-backup/` with your entire timeline of backups and copy files from it :)
- Or btrfs send/receive an entire snapshot of a specific day in the past from `backup1` to the corresponding disks and rename it to replace the live subvolume. 
