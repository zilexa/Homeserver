# Server Backup & Maintenance

Contents: 
- The 3-tier Backup Strategy outline
  1. [Disk protection](https://github.com/zilexa/Homeserver/tree/master/maintenance#1-disk-protection)
  2. [Timeline backups](https://github.com/zilexa/Homeserver/tree/master/maintenance#2-timeline-backups)
  3. [Online backup](https://github.com/zilexa/Homeserver/tree/master/maintenance#3-online-backup)
  4. [Replacing disks, restoring data](https://github.com/zilexa/Homeserver/tree/master/maintenance#4-replacing-disks-restoring-data)

- [Backup & Maintenance guide](https://github.com/zilexa/Homeserver/tree/master/maintenance#backup--maintenance-guide)
  - [Prerequisities](https://github.com/zilexa/Homeserver/tree/master/maintenance#prequisities)
  - [Snapraid setup](https://github.com/zilexa/Homeserver/tree/master/maintenance#snapraid-setup)
  - [btrbk setup](https://github.com/zilexa/Homeserver/tree/master/maintenance#backup-setup)
  - [Maintenance & scheduling](https://github.com/zilexa/Homeserver/tree/master/maintenance#maintenance--scheduling)

## The 3-tier Backup Strategy outline
### 1. disk protection
To protect against disk failure, snapraid is used to protect essential data & largest data folders. 
  - It will sync every 6 hours: you can loose max 6 hours of data if a single disk fails. You can run it more or less frequently.
  - You can easily protect 4 disks with just 1 parity disk, because the parity data uses much less space than your actual data. 
    - The concept of parity simplified: assign a number to each data disk sector, like "3" to disk1-sector1 and "4" to disk2-sector1. Calculate parity: 3+4=7. Now if disk1 fails, you can restore it from parity, since 7-4=3.
    - The downside of scheduled parity versus realtime (like raid1 or like duplication): described [here](https://github.com/automorphism88/snapraid-btrfs#q-why-use-snapraid-btrfs). But with BTRFS we overcome that issue by creating a read-only snapshot and create parity of that instead. Now, the live data can be modified between snapraid runs, but you will always be able to restore a disk. This is taken care of by `snapraid-btrfs` wrapper of `snapraid`. 

### 2. Timeline backups
The most flexible tool for backups that requires zero integration into the system is btrbk. Alternatives such as Snapper are more deeply integrated and too limiting for backup purposes. Timeshift is very user friendly, mac-like Timemachine (installed and configured via my [post-install script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script) for laptops and desktops) but not suited to backup personal data. 
With btrbk: 
- The system subvolumes (`/`, `/docker`, `/home`) and subvolumes on cache/data disks (`/Users`, `/Music`) will be snapshotted with a chosen retention policy on their respective disks in a root folder (for example /mnt/disks/data1/.backups). 
- In addition, using BTRFS native send/receive mechanism the snapshots are efficiently and securely copied to a seperate backup disk (`mnt/disks/backup1`).
- For both system subvolume backups and Users data backup, you have a nice time-line like overview of snapshots (folders) on the backup disk.
- btrbk will manage the retention policy and cleanup of both snapshots and backups. 
- Periodically (once a month or so), we connect a btrfs formatted usb-disk with label `backup2` and leave it connected for the night: btrbk will notice and send backups to both internal `backup1` and external `backup2`. How cool is that!

### 3. Online backup
We can use other tools to periodically send encrypted versions of snapshots to a cloud storage. I haven't figured this part out yet, but I did buy a pcloud.com lifetime subscription for €245 during december discounts (recommended). Most likely, this will be done via a docker container (duplicacy or duplicati or similar). 

### 4. Replacing disks, restoring data
- In case of disk failure:  insert a replacement disk and restore the data ([Snapraid manual section 4.4](https://www.snapraid.it/manual)) on it easily via snapraid. You can also use snapraid to restore individual files ([Snapraid manual section 4.3](https://www.snapraid.it/manual)) Use `snapraid-btrfs fix` instead of `snapraid fix` ([read here](https://github.com/automorphism88/snapraid-btrfs#q-can-i-restore-a-previous-snapshot)) unless your last sync was done via the latter.  
- To access the timeline backup: Make a MergerFS mount point at `/mnt/pool-backup` combining `/mnt/disks/backup1/cache.users`, `/mnt/disks/backup1/data1.users`, `/mnt/disks/backup1/data2.users` to have a single Users folder in `mnt/pool-backup/` with your entire timeline of backups and copy files from it :)
- Or btrfs send/receive an entire snapshot of a specific day in the past from `backup1` to the corresponding disks and rename it to replace the live subvolume. 

_**In conclusion: (1) we protect entire disks via snapraid (if you use only a single subvolume per disk) and on top of that (2) backup important subvolumes to a seperate internal disk and (3) periodically to an external disk. Besides that we upload encrypted backups to a 3rd party cloud service**_

***downside of Snapraid & Btrfs***: Because of btrfs snapshot feature, you can always restore, even if files changed between syncs. But snapraid does not support btrfs subvolumes: it thinks they are seperate disks.\
Until Snapraid supports subvolumes properly, you can only include [1 subvolume per disk](https://github.com/automorphism88/snapraid-btrfs/issues/15#issuecomment-805783287).\
I choose `/Users`, to protect that data via snapraid & via backups & via online backup. This means `/TV` is not protected in any way, since it is most likely too big to backup to your backup disk, unlike /Music.\
Make a choice that makes sense for your situation. For me, /TV contains expendable (can be redownloaded) data, it's a pity it cannot be protected, but it's also not a big issue. 

# Backup & Maintenance guide
### Prequisities
All prequisities have been taken care of by the script from [Step 1:Filesystem](https://github.com/zilexa/Homeserver#step-1-filesystem): snapraid, snapraid-btrfs (requires snapper), nocache and btrbk should be installed. Also the default config of snapper `/etc/snapper/config-template/default` and the snapraid config `etc/snapraid.conf` have been replaced with slightly modified versions, to save you some time and prevent you from hitting walls.\

_All you have to do:_
If you haven't downloaded this repository yet: In the root of this repository, you will see a big green button "code", click it, select download as zip. Extract the contents of the `maintenance` folder to `$HOME/docker/HOST`.\
Notice this way you have everything in 1 folder: you docker container volumes `$HOME/docker` with their config and data, your docker-compose.yml and environment file. And the `HOST` subdir containing essential maintenance config files for the host (your server). When your docker subvolume is snapshotted & backupped, so are the maintenance config files. 

## Snapraid setup
#### Step 1: Create snapper config files
Snapper is unfortunately required for snapraid when using btrfs. A modified default template should be on your system already. You need to create config files (which will be based on the default) one-by-one per subvolume you want to protect. Snapper also requires a root config, which we create but will never use: 
```sudo snapper create-config /
sudo snapper -c Users0 create-config /mnt/disks/cache/Users
sudo snapper -c Users1 create-config /mnt/disks/disk1/Users
sudo snapper -c Users1 create-config /mnt/disks/disk2/Users
sudo snapper -c Users1 create-config /mnt/disks/disk3/Users
```

#### Step 2: Adjust snapraid config file
Open /etc/snapraid.conf in an editor and adjust the lines that say "ADJUST THIS.." to your situation. 

#### Step 3: Test the above 2 steps.
`snapraid-btrfs ls` (no sudo!). Notice 3 things: 
- A confirmation it found snapper configs for each data disk in your snapraid.conf files. 
- A warning about non-existing snapraid.content files: that is correct, they will be automatically created during first sync. 
- A warning about UUIDs that cannot be used. Correct, because Snapraid will sync snapshots, not the actual subvolumes. 

#### Step 4: Run the first sync!
Now run `snapraid-btrfs sync`. That is it! It can take a long while depending on the amount of data you have. Next runs only process incremental changes and go very fast. 
- If you have big file changes, you can run `snapraid sync`, now you will sync the live data instead of the snapshots but it will be much more efficient because UUIDs can be used. Make sure you run a `snapraid-btrfs sync` after it finished (should be quick). 

The maintenance script will run this command every 6 hours. `snapraid-btrfs cleanup` will run afterwards to remove all snapshots except for the last one. 


## Backup setup
#### Step  First run of backup tasks
The command for system backups: ``
The command for user data backups: ``
**The first run should be done manually because for user data it can take HOURS**, depending on the amount of data you have. Next runs only process incremental changes and go very fast. 

## Maintenance & scheduling 
Depending on the purpose of your server, several maintenance tasks can be executed nightly, before the backup strategy is executed, to cleanup files first: 
- Delete watched tv shows, episodes, seasons and movies xx days after they have been watched. 
- Unload SSD cache: move files not modified for 30 days to the hard disks (from ssd to /mnt/pool-nocache). Since `pool-nocache` = `pool-nocache` without the SSD, the path to the moved files is the same, they are still in `/mnt/pool`, they are only moved to a different underlying disk. 
- Cleanup docker: stopped containers, old images etc can be deleted. 
- Cleaning up system cache is not necessary as those folders are already excluded since they are nested subvolumes: nested subvolumes are excluded when the parent subvol is snapshotted. 
- 
#### Choose # of days to keep files on cache.
Open `/HOST/maintenance.sh` in Pluma/text editor. 
Under Cache Cleanup, change the # of days (30) to your needs. 

#### Choose # of days to keep watched tv-media.
Open `HOST/media-cleaner/media_cleaner.conf`in Pluma/text editor. 
Change the days to keep watched episodes/seasons/movies and choose whether to keep everything marked as favourite. Those will never be deleted automatically. 


#### Create schedule for maintenance tasks that do not need root (cleanup, snapraid)
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

#### Create schedule for tasks that do need root (docker cleanup, backups)
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
--> To modify the retention policy, edit the `system-backup.conf` and `users-backup.conf` files in $HOME/docker/HOST/ using the [documentation of btrbk](https://digint.ch/btrbk/doc/btrbk.conf.5.html).\
--> Notice the first part sets the schedule, second part is the actual task, what follows is mumbo jumbo to get nice timestamps, and store the output of the tasks in in logs.\
--> If `maintenance.sh` is still running when `backup.sh` is triggered, the backup script will wait nicely for maintenance to finish before starting its run.
