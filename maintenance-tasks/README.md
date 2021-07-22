## Maintenance & scheduling 

To keep your server spinning and purring everyday like its very first day, several tasks should be executed. 
Below the tasks are explained. Note the order of execution has been chosen carefully. If you remove/add tasks, keep that in mind. 


Files location: [$HOME/docker/HOST/](https://github.com/zilexa/Homeserver/tree/master/docker/HOST)
- nightly.sh --> nightly tasks such as backups, FileRun cleanup & generation of thumbnails/previews. 
- monthly.sh --> cleanup of OS, BtrFS filesystem tasks, cleanup of Docker stale/orphaned containers/images 
- the other folders contains the tools required for the tasks. 

### NIGHTLY MAINTENANCE: Overview of tasks/tools
- [_Media-cleaner_](https://github.com/clara-j/media_cleaner): delete watched show episodes/seasons and movies X days after they have been _watched_(!). 
- [_Archiver_](https://github.com/trapexit/mergerfs#time-based-expiring): If you use MergerFS SSD cache: Unload SSD cache: move _Users_ files unmodified for >30 days to harddisk array (from /mnt/disks/ssd to /mnt/pool-nocache). Since `/mnt/pool-nocache` = `/mnt/pool` without the SSD, the path to the moved files stays is the same, they are still in `/mnt/pool`, they are only moved to a different underlying disk. 
    - Exceptions to this task: Keep thumbnails created by FileRun and DigiKam (photo management software) on the SSD, for performance and power consumption purposes (the HDDs won't turn on when you scroll through your photos via FileRun). 
    - Also do not move files moved to trash.
    - do not attempt to move btrfs read-only snapshots.  
- [_btrbk_](https://digint.ch/btrbk/): BtrFS swiss-knife for backups. See [Backup Strategy](https://github.com/zilexa/Homeserver/tree/master/backup-strategy). 
- [_snapraid-btrfs_](https://github.com/automorphism88/snapraid-btrfs): Basically similar to "scheduled RAID" instead of normal raid, for parity-based backups. See [Backup Strategy](https://github.com/zilexa/Homeserver/tree/master/backup-strategy).
- _Disk health scan_: run S.M.A.R.T. scan to update [Scrutiny](https://github.com/AnalogJ/scrutiny) container. 

### MONTHLY MAINTENANCE: Overview of tasks/tools
- [_Bleachbit_](https://www.bleachbit.org/): Cleanup host OS filesystem, temp, cache, bin, old update files, old logs etc. Runs twice: normal and with elevated rights.
- [_pullio_](https://hotio.dev/pullio/): Auto-update labeled docker images (only used for Media related images. Do not use for other images!).
- [_duin_](https://crazymax.dev/diun/): Check labeled docker images for updates, user can decide to update after verifying update is stable. 
- _Docker housekeeping_: remove dangling images and volumes. 
- _BtrFS housekeeping_: balancing & scrubbing disks. Note for the backup disk, the monthly task is actually in the Nightly script, since the disk needs to be mounted, best to run monthly right after completing nightly backup. 


### 1. Get the files
Download the files to your HOST dir. If you completed the Backup guide, you should already have this folder and the btrbk, snapraid files (do not overwrite your own versions!):
[$HOME/docker/HOST/](https://github.com/zilexa/Homeserver/tree/master/docker/HOST)

#### Cofigure Media Cleaner
1. Get the media_cleaner.py in your `HOST/media-cleaner` folder file by opening it, hit the RAW button and use your browser to Save As (CTRL+S): https://github.com/clara-j/media_cleaner
2. Open a Terminal window from this folder, run the script to connect it to Jellyfin: `python3 media_cleaner.py` \
A file `HOST/media-cleaner/media_cleaner.conf` will be created. Modify at will if you need to change the configuration.

#### Configure Archiver, MergerFS SSD cache unloading
Verify the paths are correct in the 2 files in `HOST/archiver/`. 

### 2. Schedule the 2 tasks!
- In terminal (CTRL+ALT+T) open Linux scheduler`sudo crontab -e` and copy-paste the below into it. Make sure you replace the existing MAILTO, and optionally add your email address between "", this way you will receive slightly cryptic error messages if the commands could not be executed. 
```
MAILTO=""
30 5 * * * /usr/bin/bash /home/asterix/docker/HOST/nightly.sh
50 5 * * 7 run-if-today L zo && /usr/bin/bash /home/asterix/docker/HOST/monthly.sh
```
Note this means:
- Nightly will start 5.30 AM every day.
- Monthly will start 20min later at 5.50 AM, every first Sunday of the month. 
- The Nightly script creates a file "tasks-running" and deletes the file when the script is finished.
- The Monthly script checks if such a file exists, waits for it to disappear, then starts running its tasks (how neat!). 
Feel free to change the schedule. [This calculator](https://crontab.guru/) will help you, additionally check how to use [run-if-today](https://github.com/xr09/cron-last-sunday/blob/master/run-if-today). 

