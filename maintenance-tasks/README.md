## Maintenance Tasks & Scheduling

To keep your server spinning and purring everyday like its very first day, several tasks should be executed automatically on a regular basis.  
Below the tasks are explained. Note the order of execution has been chosen carefully. If you remove/add tasks, keep that in mind. 

The prep-server.sh script has downloaded the tools and scripts to `$HOME/docker/HOST/`. Most importantly: 
- nightly.sh 
- monthly.sh 
- /logs
- the other folders contain necessary tools and their configs.  

&nbsp;

### NIGHTLY MAINTENANCE: Overview of tasks/tools
- [_Media-cleaner_](https://github.com/clara-j/media_cleaner): delete watched shows episodes/seasons and movies X days after they have been _watched_(!) highly recommended, requires much less data if you automatically delete watched content after 5-10 days! For example, a single 2TB SSD is enough for my `/mnt/pool/Media`.
- [_Archiver_](https://github.com/trapexit/mergerfs#time-based-expiring): If you use MergerFS SSD cache: Unload SSD cache: move _Users_ files unmodified for >30 days to harddisk array (from /mnt/disks/ssd to /mnt/pool-nocache). Since `/mnt/pool-nocache` = `/mnt/pool` without the SSD, the path to the moved files stays is the same, they are still in `/mnt/pool`, they are only moved to a different underlying disk. 
    - Exceptions to this task: Keep thumbnails created by FileRun and DigiKam (photo management software) on the SSD, for performance and power consumption purposes (the HDDs won't turn on when you scroll through your photos via FileRun). 
    - Also do not move files moved to trash.
    - do not attempt to move btrfs read-only snapshots.  
- [_btrbk_](https://digint.ch/btrbk/): BtrFS swiss-knife for backups. See [Backup Strategy](https://github.com/zilexa/Homeserver/tree/master/backup-strategy). 
- [_snapraid-btrfs_](https://github.com/automorphism88/snapraid-btrfs): Basically similar to "scheduled RAID" instead of normal raid, for parity-based backups. See [Backup Strategy](https://github.com/zilexa/Homeserver/tree/master/backup-strategy).
- _Disk health scan_: run S.M.A.R.T. scan to update [Scrutiny](https://github.com/AnalogJ/scrutiny) container. 
- _Filerun container tasks_: Apart from cleanup, these tasks are only necessary when adding/deleting/modifying files/folders _outside_ of the filerun WebUI or connected WebDAV apps. Without running these tasks, you will _still_ see the files in FileRun and webDAV apps just fine, since FileRun simply shows you a realtime view of your filesystem. Such files just won't appear in search results and their thumbnails & quick previews will be empty. Note these commands will be run from within the container. 

### MONTHLY MAINTENANCE: Overview of tasks/tools
- [_Bleachbit_](https://www.bleachbit.org/): Cleanup host OS filesystem, temp, cache, bin, old update files, old logs etc. Runs twice: normal and with elevated rights.
- [_pullio_](https://hotio.dev/pullio/): Auto-update labeled docker images (only used for Media related images. Do not use for other images!).
- [_duin_](https://crazymax.dev/diun/): Check labeled docker images for updates, user can decide to update after verifying update is stable. 
- _Docker housekeeping_: remove dangling images and volumes. 
- _BtrFS housekeeping_: balancing & scrubbing disks. Note for the backup disk, the monthly task is actually in the Nightly script, since the disk needs to be mounted, best to run monthly right after completing nightly backup. 

&nbsp;


### STEP 1: Decide what tools and tasks you need
- If you do not use a MergerFS Tiered Cache drive: remove the Archiver command from the Nightly script. 
- If you do not download series/movies/etc: remove Mediacleaner command and its folder. 
- If you are not planning to use SnapRAID, remove the command and its folder and uninstall Snapper and Snapraid:  


### STEP 2: Configure Archiver, MergerFS SSD cache unloading
- Verify the paths are correct in the 2 files in `HOST/archiver/`.
- Notice the exclude list, it excludes filerun hidden folders, this way your photo thumbnails/previews stay on your fast SSD. 


### STEP 3: Configure Media Cleaner
- Open a Terminal window from `$HOME/docker/HOST/mediacleaner` (right click in that folder > Open Terminal), run the script for initial one-time config:
```
python3 media_cleaner.py
```
- Follow the steps.
- A file `HOST/media-cleaner/media_cleaner.conf` will be created. Done! To change your settings, Simply edit the .conf file in your text editor.

### STEP 4. Schedule Nightly and Monthly
- In terminal (CTRL+ALT+T) open Linux scheduler`sudo crontab -e` and copy-paste the below into it. Make sure you replace the existing MAILTO and _do not_ fill in your emailaddress otherwise you will receive cryptic error messages, use `""` instead. 
```
MAILTO=""
30 5 * * * /usr/bin/bash /home/YOURUSERNAME/docker/HOST/nightly.sh
50 5 * * 7 run-if-today L zo && /usr/bin/bash /home/YOURUSERNAME/docker/HOST/monthly.sh
```
Note this means:
- Nightly runs at 5.30 AM every day.
- Monthly runs every first Sunday of the month at 5.50AM. 
- Feel free to change the schedule. [This calculator](https://crontab.guru/) will help you, additionally check how to use [run-if-today](https://github.com/xr09/cron-last-sunday/blob/master/run-if-today). 
- If Nightly happens to still be running while Monthly is executed, Monthly pauses until Nightly is done (see how the scripts start and end).  
<sub>The Nightly script creates a file "tasks-running" and deletes the file when the script is finished. The Monthly script checks if such a file exists, waits for it to disappear, then starts running its tasks :). </sub>

#### Optional: change frequency of snapshots/backups
- If you want to create snapshots and backups more frequently: move the single `SUBVOLUMES SNAPSHOTS & BACKUPS` command from the `nightly.sh` script to crontab and set a schedule like the above but more frequently, like every 6 hours. 
- `btrbk` has been configured to only save 1 snapshot per day, this means during the first run the next day, it will delete the previous day snapshots except for the latest, otherwise it can cost a lot of storage if you save multiple snapshots of the past days. 

#### Optional: change frequency of SnapRAID
- See the previous step: [Backup Strategy](https://github.com/zilexa/Homeserver/tree/master/backup-strategy)
- If you want to run SnapRAID more frequently move the single SnapRAID command from the `nightly.sh` script to your crontab and set a schedule like the above but more often. 

For example, you could run Snapraid every hour. The Snapraid command will create hourly snapshots and you will be able to restore files or entire subvolumes, loosing no more than 1 hour of data. This is similar to the level of disaster recovery protection seen in datacenters for corporate, mission critical applications. Note Snapper has been configured to only store the latest snapshot. Keeping older snapshots has no usecase for SnapRAID. 

Note the snapshots created specifically for SnapRAID are seperate from the snapshots created by btrbk, which maintains a timeline (X days, X weeks, X months) and copies snapshots to backup drives. 


