# Server Maintenance & Backup system

## Maintenance tasks
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

### Step 3: set schedule for tasks.
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
--> To modify the schedule, this cron schedule calculator helps: https://crontab.guru/ 
--> Notice the first part sets the schedule, second part is the actual task, what follows is mumbo jumbo to get nice timestamps, and store the output of the tasks in in logs.  
--> keep snapraid-btrfs in there and move on to the Backup subguide. 
