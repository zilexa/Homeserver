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

```
MAILTO=""
30 5 * * * /usr/bin/bash /home/asterix/docker/HOST/nightly.sh
50 5 * * 7 run-if-today L zo && /usr/bin/bash /home/asterix/docker/HOST/monthly.sh
```
