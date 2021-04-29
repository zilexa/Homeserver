# Server Backup & Maintenance

Contents:
  - [Prerequisities](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#prequisities)
  - [Snapraid setup](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md#snapraid-setup)
  - [Backup setup](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md#backup-setup)
  - [Maintenance & scheduling](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/README.md#maintenance--scheduling)


# Backup & Maintenance guide
### Prequisities
All prequisities have been taken care of by the script from [Step 3:Prepare Server & Docker](https://github.com/zilexa/Homeserver/blob/master/prepare-server-docker.sh).
- This script installed the tools (btrbk for backups, snapraid/snapraid-btrfs/snapraid-btrf-runner for backups and additional tools) but more importantly also added configuration files (based on the tools default example) that are almost ready to use. The script downloaded them from this folder to your `$HOME/docker/HOST/` folder. 
- By storing these files outside of your OS system dir (`etc/system`) you have your entire configuration independent of OS and backupped as a whole (`HOME/docker`). The files are symlinked into the system folder.  

_All you have to do:_
- If you haven't executed that script, [open the script](https://github.com/zilexa/Homeserver/blob/master/prepare-server-docker.sh) and execute the commands to install the required tools and obtain the config files, or go back and perform [step 3](https://github.com/zilexa/Homeserver/blob/master/prepare-server-docker.sh)](https://github.com/zilexa/Homeserver/blob/master/prepare-server-docker.sh) first. 

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
Open `/etc/snapraid.conf` in an editor and adjust the lines that say "ADJUST THIS.." to your situation. 

#### Step 3: Test the above 2 steps.
Run `snapraid-btrfs ls` (no sudo!). Notice & verify 3 things: 
- A confirmation it found snapper configs for each(!) data disk in your snapraid.conf file. 
- A (correct) warning about non-existing snapraid.content files for each content-file location you defined in snapraid.conf, they will be automatically created during first sync. 
- A warning about UUIDs that cannot be used. Correct, because Snapraid will sync snapshots, not the actual subvolumes. You won't get this errror if you sync the live filesystem with `snapraid sync`. 

#### Step 4: Run the first sync!
Now run `snapraid-btrfs sync`. That is it! It can take a long while depending on the amount of data you have. Next runs only process incremental changes and go very fast. 
- If you have big file changes, you can run `snapraid sync`, now you will sync the live data instead of the snapshots but it will be much more efficient because UUIDs can be used. Make sure you run a `snapraid-btrfs sync` after it finished (should be quick). 

The maintenance script will run this command every 6 hours (you can change it). `snapraid-btrfs cleanup` will run afterwards to remove all snapshots except for the last one. 

#### Step 5: (optional) Install the Runner script
A script exists that takes care of running the sync command, scrub data (verifies parity file), clean up all but the latest snapshots, log everything to file and send email notifications when done. 
Follow the steps to get the script, it will run from $HOME/docker/HOST/snapraid-btrfs-runner. 
```
cd $HOME/docker/HOST
wget https://github.com/fmoledina/snapraid-btrfs-runner/archive/refs/heads/master.zip
unzip master
rm master.zip
mv snapraid-btrfs-runner-master snapraid-btrfs-runner
```
Now modify the conf file, section `[email]` to add your emailaddress, the "from" emailaddress corresponding with your smtp provider account and add the smtp provider server details:\
`nano snapraid-btrfs-runner/snapraid-btrfs-runner.conf`, save changes with CTRL+C and CTRL+O.\
Run it to test it works: `python3 snapraid-btrfs-runner.py`

&nbsp;

## Backup setup
The btrbk config file has been carefully created and tested:\
It will create snapshots in the root of the disks to give you a "timeline", date & time stamped view of all available backups in the `timeline` folder of each disk. Incremental backups will be sent to your internal backup disk and, if a USB disk is connected (!), the incremental backups are also sent to that disk.\
No other tool allows you to do all that automatically. The config file is also easy to understand and to adjust to your needs.\
It was a HELL to figure out though, as the `btrk` guide assumes you are a pro. 

#### Step 1: Get the configuration & adjust settings, retention policy to your needs
- Download the config file: `cd $HOME/docker/HOST` and `wget -P https://raw.githubusercontent.com/zilexa/Homeserver/master/maintenance/btrbk-backup.conf`
- Open the file located in $HOME/docker/HOST/btrbk-backup.conf
- Edit the default retention policy to your needs. Also edit the custom retention policy for your system disk subvolumes. 
- Verify the locations of your disks, the chosen subvolume (Users) meet your needs. 
- Remove the lines containing `/media/backup2/...` if you are not planning on connecting a USB disk occasionally. This will also prevent warnings/errors when the disk is not connected. 

#### Step 2: Create the snapshot location and backup target location folders
- For timeline backups of the system, snapshots will be stored in `/mnt/systemroot/timeline`. 
- For timeline backups of the cache/data disks, snapshots will be stored in each disks root, `.timeline` folder, hidden for security. 
- The target for backups is your disk mounted at `/mnt/backup1/`, it should not be part of your MergerFS pool.

2.1. Mount the filesystem root of the system disk and the backup disk.  
```
sudo mount /dev/nvme0n1p2 /mnt/system-root -o subvolid=5,defaults,noatime,compress=lzo 
sudo mount -U !!!UUID OF BACKUPDRIVE HERE!!! /mnt/disks/backup1 -o subvolid=backup,defaults,noatime,compress=zstd:8 
```` 

2.2. Create destination folders: 
- For the system snapshots: `sudo mkdir /mnt/systemroot/timeline`
- For cache/data disks snapshots: `sudo mkdir /mnt/disks/cache/.timeline` and `sudo mkdir /mnt/disks/data1/.timeline` etc. 
- For backups: `sudo mkdir /mnt/disks/backup1/system`, `sudo mkdir /mnt/disks/backup1/cache`, `sudo mkdir /mnt/disks/backup1/data1` etc. 

#### Step 3: Perform a dryrun
A dryrun will not perform any actions: 
`btrbk -n -c /home/$SUDO_USER/docker/HOST/backup.conf run`
Note you should only see errors regarding `backup2` if it is not connected. Snapshots are still created and backups are made on the first target `backup1`. 

#### Step 4: Run initial backups
Do this manually before activating the schedules in the next steps. The first time can take hours depending on your data. 
`btrbk-c /home/$SUDO_USER/docker/HOST/backup.conf run`

&nbsp;

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
