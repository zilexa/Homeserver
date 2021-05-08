# STEP 4: Server Backup & Maintenance Guide
## SYNOPSIS: [Backup Strategy](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/backupstrategy.md)

Contents:
  - [Prerequisities](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#prequisities)
  - [I. Configure parity-based backups](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md#snapraid-setup)
  - [II. Configure subvolume backups](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md#backup-setup)
  - III. Configure auto-archiving to USB disk((https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md)
  - [Maintenance & scheduling](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md#maintenance--scheduling)


### Prequisities
All prequisities have been taken care of by the script from [Step 3:Prepare Server & Docker](https://github.com/zilexa/Homeserver/blob/master/prepare-server-docker.sh).
- This script installed the tools (btrbk for backups, snapraid/snapraid-btrfs/snapraid-btrf-runner for backups and additional tools) but more importantly also added configuration files (based on the tools default example) that are almost ready to use. The script downloaded them from this folder to your `$HOME/docker/HOST/` folder. 
- By storing these files outside of your OS system dir (`etc/system`) you have your entire configuration independent of OS and backupped as a whole (`HOME/docker`). The files are symlinked into the system folder.  

_All you have to do:_
- Make sure you have done [step 3](https://github.com/zilexa/Homeserver/blob/master/docker) first or select the essential parts of the [prepare-server-docker.sh](https://github.com/zilexa/Homeserver/blob/master/prepare-server-docker.sh) script and execute the commands to install the required tools and obtain the config files, or go back and perform first. 

## I: Configure parity-based backups _via snapraid-btrfs_
#### Step 1: Create snapper config files
Snapper is unfortunately required for snapraid when using btrfs. A modified default template should be on your system already. You need to create config files (which will be based on the default) one-by-one per subvolume you want to protect. Snapper also requires a root config, which we create but will never use: 
`sudo snapper create-config /` \
Now go ahead and create the Snapper config for each subvolume (max 1 per disk!). For example: `sudo snapper -c data0 create-config /mnt/disks/data0/Media` and `sudo snapper -c data1 create-config /mnt/disks/data1/Users` and `sudo snapper -c data2 create-config /mnt/disks/data2/Users`.

#### Step 2: Adjust snapraid config file
Open `/etc/snapraid.conf` in an editor and adjust the lines that say "ADJUST THIS.." to your situation. Note for each data disk, a snapper-config from the prev step must exist.

#### Step 3: Test the above 2 steps.
Run `snapraid-btrfs ls` (no sudo!). Notice & verify 3 things: 
- A confirmation it found snapper configs for each(!) data disk in your snapraid.conf file. 
- A (correct) warning about non-existing snapraid.content files for each content-file location you defined in snapraid.conf, they will be automatically created during first sync. 
- A warning about UUIDs that cannot be used. Correct, because Snapraid will sync snapshots, not the actual subvolumes. You won't get this errror if you sync the live filesystem with `snapraid sync`. 

#### Step 4: Run the first sync!
Now run `snapraid-btrfs sync`. That is it! It can take a long while depending on the amount of data you have. Next runs only process incremental changes and go very fast. 

#### Step 5: Configure mail notifications
A script exists that takes care of running the sync command, scrub data (verifies parity file), clean up all but the latest snapshots, log everything to file and send email notifications when done. 
- Modify `$HOME/docker/HOST/snapraid-btrfs-runner` section `[email]` to add your emailaddress, the "from" emailaddress corresponding with your smtp provider account and add the smtp provider server details:\
Run it to test it works: `python3 snapraid-btrfs-runner.py` This should run snapraid-btrfs sync just like in step 3 and send you an email when done. 
- Note: compared to the default snapraid-btrfs-runner, I have replaced the `mail` command for `s-nail` otherwise you need to do a whole lot more configuration (Postfix) to support `mail` on your system. 

&nbsp;

## II: Configure subvolume backups _via btrbk_
The btrbk config file has been carefully created and tested to:
- Create timestamped snapshots in the root of the disks, giving you a timeline view of your subvolumes in the `timeline` folder of each disk. 
- Incremental backups will be sent to your internal backup disk, multiple disks can be added.
- Allows you to run a backup actions manually for multiple subvolumes by using groups. 
- Allows you to archive (copy) backups to BTRFS USB disks easily. 
No other tool allows you to do all that automatically. The config file is also easy to understand and to adjust to your needs.\

#### Step 1: Create the snapshot location and backup target location folders
- We need access to the OS disk filesystem root and the backup disk, mount both:
  - `sudo mount /mnt/disks/backup1` 
  - `sudo mount /mnt/system` 
- Create the folder to store snapshots of the OS disk: `sudo mkdir /mnt/system/timeline`
- Similarly, create a `.timeline` (note the dot) folder in the root of each cache/data disk, for example `sudo mkdir /mnt/disks/data1/.timeline`
- In `/mnt/disks/backup1/`, create all destination folders for system and each data disk, for example via: `sudo mkdir /mnt/disks/backup1/{system,data1,data2,cache}`

#### Step 2: Get the configuration & adjust settings, retention policy to your needs
- Open the file located in `$HOME/docker/HOST/btrbk/btrbk.conf`
- Read and understand the taxonomy, the order and the hierarchy. Change to your disk situation (verify paths of volumes, subvols, targets) Do not change the order or the indentation! 
- Edit the default retention policy used for data disks and the system-specific retention policy to your needs. Understand there are limits: if you create 10 snapshots of 1TB of data right now, it costs you 1TB in total. But when you start making big changes to your data and regular snapshots, this will cost lots of space as it deviates more and more from your oldest snapshot and backup. 
- Edit the file `$HOME/docker/HOST/btrbk/btrbk-mail.sh` and: 1) change the email subject to your server name and 2) make sure the mount targets are correct, see the example fstab: you should have a mount for the backup disk and a mount for the btrfs-root of your system OS disk.  

#### Step 3: Perform a dryrun
When you think your btrbk.conf file is correct, do a dryrun, it will not perform a simulation: 
`sudo btrbk -n run`
When all is well, run the same command without "-n", this will perform all snapshot and backup actions, first time can take lots of time, after that, backups will be incremental. 

&nbsp;

## III. Configure auto-archiving to USB disk _via btrbk_


THE BELOW IS OUTDATED. WILL BE FIXED NEXT WEEK. THE UP TO DATE NIGHTLY.SH AND MONTHLY.SH ARE AVAILABLE IN THIS REPOSITORY.
## Maintenance & scheduling 
Depending on the purpose of your server, several maintenance tasks can be executed nightly, before the backup strategy is executed, to cleanup files first: 
- Delete watched tv shows, episodes, seasons and movies xx days after they have been watched. 
- Unload SSD cache: move _Users_ files not modified for 30 days to the hard disks (from ssd to /mnt/pool-nocache). Since `pool-nocache` = `pool without the SSD`, the path to the moved files is the same, they are still in `/mnt/pool`, they are only moved to a different underlying disk. 
    - Exceptions to this task: Keep thumbnails created by FileRun and DigiKam (photo management software) on the SSD, for performance and power consumption purposes (the HDDs won't turn on when you scroll through your photos via FileRun). 
    - Also do not move files moved to trash.
    - do not attempt to move snapshots.  
- Cleanup docker: stopped containers, old images etc can be deleted. 
- Cleaning up system cache is not necessary as those folders are already excluded since they are nested subvolumes: nested subvolumes are excluded when the parent subvol is snapshotted. 
- 
#### Choose # of days to keep files on cache.
Open `/HOST/run-cleanup.sh` in Pluma/text editor. 
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
30 2 * * * /usr/bin/bash /home/asterix/docker/HOST/run-cleanup.sh | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /home/asterix/docker/HOST/logs/maintenance.log 2>&1
#
# Every 6hrs between 10.00-23.00 do additonal snapraid-btrfs runs
0 10-23/6 * * * python3 snapraid-btrfs-runner.py
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
