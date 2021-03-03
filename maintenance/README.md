# Server Maintenance & Backup system

# 1. Maintenance tasks
Depending on the purpose of your server, several maintenance tasks can be executed nightly: 
- Delete watched tv shows, episodes, seasons and movies xx days after they have been watched. 
- Unload SSD cache: move files not modified for 30 days to the hard disks (to /mnt/pool-archive). The files will be unchanged in /mnt/pool, only their physical location is changed. 

### Requirements
Copy the folders and files in this folder to `$HOME/docker/HOST`. 
Notice this way you have everything in 1 folder: you docker container volumes with their config and data, your docker-compose.yml and environment file and your folder with maintenance and backup config. 

### Step 1: Choose # of days to keep files on cache.
Open `/HOST/maintenance.sh` in Pluma/text editor. 
Under Cache Cleanup, change the # of days (30) to your needs. 

### Step 2: Choose # of days to keep watched tv-media.
Open `HOST/media-cleaner/media_cleaner.conf`in Pluma/text editor. 
Change the days to keep watched episodes/seasons/movies and choose whether to keep everything marked as favourite. Those will never be deleted automatically. 

### Step 3: First run of snapraid-btrfs
The command (no sudo): `snapraid-btrfs sync`
Make sure there are no errors. Some warnings about UUIDs are normal. 
**The first run should be done manually because it can take HOURS**, depending on the amount of data you have. Next runs only process incremental changes and go very fast. 

### Step 4: set schedule for tasks.
Now in terminal (CTRL+ALT+T) open Linux scheduler (no sudo): `crontab -e` and copy-paste the below into it. Make sure you replace MAILTO: 
```
# Disable errors appearing in syslog
MAILTO=""
# Nightly at 02.30h run maintenance (tv-media cleanup, cache archiver, snapraid-btrfs, snapraid-btrfs cleanup)
30 2 * * * /usr/bin/bash /home/asterix/docker/HOST/maintenance.sh | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /home/asterix/docker/HOST/logs/maintenance.log 2>&1
#
# Every 6hrs between 10.00-23.00 do additonal snapraid-btrfs runs
0 10-23/6 * * * snapraid-btrfs sync | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> $HOME/docker/HOST/logs/snapraid-btrfs.log 2>&1
```

# 2. Disk Protection & File Backup

## Disk protection
- To protect the filesytem, SnapRAID will calculate parity of the drives and store it on the parity drives.
- The concept of parity simplified: assign a number to each data disk sector, like "3" to disk1-sector1 and "4" to disk2-sector1. Calculate parity: 3+4=7. Now if disk1 fails, you can restore it from parity, since 7-4=3.
- If a disk fails, you can insert a replacement disk and restore the data on it easily, but you can also use snapraid to restore individual files easily! 
- Snapraid can be run nightly, however it does have a disadvantage described [here](https://github.com/automorphism88/snapraid-btrfs#q-why-use-snapraid-btrfs). 
- That is why we use snapraid-btrfs wrapper: now BtrFS snapshots are made first before each snapraid run, allowing you to always have the ability to restore data easily, without having to worry about modified data on the data disks between snapraid runs. Genius!

## Backups
The most flexible tool for backups that requires zero integration into the system is btrbk. Alternatives such as Snapper are more deeply integrated and too limiting for backup purposes. Timeshift is very user friendly, mac-like Timemachine (installed and configured via my post-install script) but not suited to backup personal data. 
With btrbk: 
- System drive subvolumes (/, home and docker) will be snapshotted with a chosen retention policy.
- In addition, the system drive subvolume snapshots are backupped using native capabilities of BtrFS (`btrfs send-receive`).
- data folder mnt/pool/Users is a MergerFS pool, not a BtrFS subvolume. It is first incrementally synced to the backup disk then snapshotted to adhere to your chosen retention policy.
- For both system subvolume backups and Users data backup, you have a nice time-line like overview of snapshots (folders) on the backup disk. 

### Requirements
- All requirements (snapraid, snapraid-btrfs and snapper) have been taken care of during filesystem configuration by execution of Step 3, setup-storage.sh. 
- `/etc/snapraid.conf` and `/etc/snapper/.conf` have also been downloaded and copied there by `setup-storage.sh`, note a copy of those files is available in `HOST/snapraid-btrfs/` as backup.  

### Step 1 configure snapper (required for snapraid-btrfs)
- Make copies of `/etc/snapper/config/.conf` in that same dir to reflect the # of data disks you have. 
- Rename the files to match your disk labels. 
- Open each files and set the correct mount point path of the disk.

### Step 2 configure snapraid
- Open `/etc/snapraid.conf` and make changes to section 1 (parity disk path), section 3 (# of data AND parity disks and their path) and section 4 (data disks including cache). 

### Step 3 create the necessary folders
- On each data disk (for example `/mnt/disks/cache` and `/mnt/disks/data1`) create a folder `.snapshots`, because of the dot it will be hidden by default. Note this folder should be accessible by the user, not just root. This will contain the snapshots (which are in fact subvolumes) of the disk before snapraid is run.
- On each data disk and the cache disk, a separate subvolume needs to be created to store snapraid content files: `sudo btrfs subvolume create /mnt/disks/data1/.snapraid` this way the content files are excluded. 

### Step 4 First run of backup tasks
The command for system backups: ``
The command for user data backups: ``
**The first run should be done manually because for user data it can take HOURS**, depending on the amount of data you have. Next runs only process incremental changes and go very fast. 

### Step 5 create the backup schedule
Note: The backup schedule requires root, as `btrbk` needs it. Root has its own scheduler. Do not mix up these two crontabs. 
- In terminal (CTRL+ALT+T) open Linux scheduler: `sudo crontab -e` and copy-paste the below into it. Make sure you replace MAILTO: 

```
# Disable errors appearing in syslog
MAILTO=""
#
# Nightly at 03.00h run backup tasks and tune power consumption
0 3 * * * /usr/bin/bash /home/asterix/docker/HOST/backup.sh | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /home/asterix/docker/HOST/logs/backup.log 2>&1
```

--> To modify the schedule, this cron schedule calculator helps: https://crontab.guru/ \
--> To modify the retention policy, edit the `system-backup.conf` and `users-backup.conf` files in $HOME/docker/HOST/ using the [documentation of btrbk](https://digint.ch/btrbk/doc/btrbk.conf.5.html). 
--> Notice the first part sets the schedule, second part is the actual task, what follows is mumbo jumbo to get nice timestamps, and store the output of the tasks in in logs.\
--> If `maintenance.sh` is still running when `backup.sh` is triggered, the backup script will wait nicely for maintenance to finish before starting its run.
