Contents: 
  1. [Disk protection](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/backupstrategy.md#1-disk-protection)
  2. [Timeline backups](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/backupstrategy.md#2-timeline-backups)
  3. [Online backup](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/backupstrategy.md#3-online-backup)
  4. [Replacing disks, restoring data](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/backupstrategy.md#4-replacing-disks-restoring-data)


## The 3-tier Backup Strategy outline
### 1. disk protection 
To protect against disk failure, SnapRAID is used to protect essential data & largest data folders. 
  - It does not duplicate files to a backup location, instead it will calculate parity for the selected subvolumes. 
  - This way with a single parity disk you can protect 4 data disks against single-disk failure. 
  - Parity is updated/synced on a schedule that you choose (once a day at night or every 6 hrs). 
  - The downside of scheduled parity versus realtime (like traditional raid): described [here](https://github.com/automorphism88/snapraid-btrfs#q-why-use-snapraid-btrfs). Snapraid-btrfs leverages the BTRFS filesystem to overcome that issue by creating a read-only snapshot and create parity of that instead of the live filesytem. Now, the live data can be modified between snapraid runs, but you will always be able to restore the last snapshot (entirely or per file). This is taken care of by `snapraid-btrfs` wrapper of `snapraid`.
  - The `snapraid-btrfs-runner` script wraps around that just to send email notifications.  
  - LIMITAION: you can only configure 1 subvolume per disk. If you store /Media and /Users on the same disk, the logical choice would be to protect /Users with SnapRAID. 
  - Since /Media can contain huge files (movies, seasons in 4K) that often change, you might not want to snapshot that subvolume at all, as it will cost you more storage.   

### 2. Timeline backups
The most flexible tool for backups that requires zero integration into the system is btrbk. Alternatives: 
1. Snapper, does not do backups, only snapshots and creates them against logic within the snapshotted subvolume. 
2. Timeshift, very user friendly and already takes care of automatic snapshots before system updates and regular snapshots configured in its interface. Also, it adds them to the boot menu, allowing you to easily "go back in time" when there is a system failure. But Timeshift cannot send those snapshots to other locations. 
With [btrbk](https://digint.ch/btrbk), for a short, quick btrbk guide [read this](https://wiki.gentoo.org/wiki/Btrbk):  
- Your `Users` snapshot on all `dataX` drives can be snapshotted with a chosen retention policy on their respective disks in a root folder (for example `/mnt/disks/data1/snapshots`). 
- In addition, using BTRFS native send/receive mechanism the snapshots are efficiently and securely copied to a seperate backup disk (`mnt/disks/backup1`).
- For all snapshots/backups, you have a nice timeline-like overview of snapshots (folders) on the backup disk and in the `snapshots` folder of each disk. 
- btrbk will manage the retention policy and cleanup of both snapshots and backups. 
- Periodically, connect a USB disk (`backup2`, `backup3`), btrbk will notice and immediately send all backups from the backup disk to the connected disk. This is called archiving. Note the UUID of the connected USB disk needs to be configured in the system first.
- Leveraging Timeshift by sending its system snapshots to backup targets is under investigation, see [Timeshift feature request](https://github.com/linuxmint/timeshift/issues/16) and [btrbk discussion](https://github.com/digint/btrbk/issues/480). 

### 3. Online backup
We can use other tools to periodically send encrypted versions of snapshots to a cloud storage. I haven't figured this part out yet, but I did buy a pcloud.com lifetime subscription for €245 during december discounts (recommended). Most likely, this will be done via a docker container (duplicacy or duplicati or similar). 

### 4. Replacing disks, restoring data
- btrfs has its own `replace` command that should be used to replace disks, unless the disk has failed. 
- In case of disk failure:  insert a replacement disk and restore the data ([Snapraid manual section 4.4](https://www.snapraid.it/manual)) on it easily via snapraid. You can also use snapraid to restore individual files ([Snapraid manual section 4.3](https://www.snapraid.it/manual)) Use `snapraid-btrfs fix` instead of `snapraid fix` ([read here](https://github.com/automorphism88/snapraid-btrfs#q-can-i-restore-a-previous-snapshot)) unless your last sync was done via the latter.  
- To access all the disks timeline backups in 1 overview: create a MergerFS mount point (`/mnt/pool-backup`) combining `/mnt/disks/backup1/cache.users`, `/mnt/disks/backup1/data1.users`, `/mnt/disks/backup1/data2.users` to have a single Users folder in `mnt/pool-backup/` with your entire timeline of backups and copy files from it :)
- Or btrfs send/receive an entire snapshot of a specific day in the past from `backup1` to the corresponding disks and rename it to replace the live subvolume. 

_**In conclusion: (1) protect all subvolumes (`/Media` and `/Users`) using parity via SnapRAID-btrfs (2) backup non-expendable subvolumes (`/Users`) to a seperate internal disk and (3) periodically archive backups to an external disk automatically and 4) we upload encrypted backups (`/Users`) to a 3rd party cloud service**_
