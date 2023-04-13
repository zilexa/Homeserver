## Maintenance Tasks & Scheduling

To keep your server spinning and purring everyday like its very first day, several tasks should be executed automatically on a regular basis.  
Below the tasks are explained. Note the order of execution has been chosen carefully. If you remove/add tasks, keep that in mind. Also note, depending on your setup and hardware, tasks are optional. 

The prep-server.sh script has downloaded the tools and scripts to `$HOME/docker/HOST/`. Most importantly: 
- [/docker/HOST/btrbk/btrbk-mail.sh](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/btrbk) also see [I. BTRFS subvolume backups](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#ii-configure-subvolume-backups-via-btrbk)
- [/docker/HOST/nightly.sh](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/nightly.sh)
- [/docker/HOST/monthly.sh](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/monthly.sh)


The other folders contain the tools used and their config files. 

&nbsp;

## Overview of Tasks and Tools

### NIGHTLY MAINTENANCE: Optional tasks only
The Nightly script contains tasks only relevant if you 1) use MerferFS with caching, 2) use parity based backups 3) modify user files outside of FileRun realm. 

- [_Archiver_](https://github.com/trapexit/mergerfs#time-based-expiring): If you use MergerFS SSD cache: Unload SSD cache: move _Users_ files unmodified for >30 days to harddisk array (from /mnt/disks/ssd to /mnt/pool-nocache). Since `/mnt/pool-nocache` = `/mnt/pool` without the SSD, the path to the moved files stays is the same, they are still in `/mnt/pool`, they are only moved to a different underlying disk. 
    - Exceptions to this task: Keep thumbnails created by FileRun and DigiKam (photo management software) on the SSD, for performance and power consumption purposes (the HDDs won't turn on when you scroll through your photos via FileRun). 
    - Also do not move files moved to trash.
    - do not attempt to move btrfs read-only snapshots.  
- _Filerun container tasks_: Apart from cleanup, these tasks are only necessary when adding/deleting/modifying files/folders _outside_ of the filerun WebUI or connected WebDAV apps. Without running these tasks, you will _still_ see the files in FileRun and webDAV apps just fine, since FileRun simply shows you a realtime view of your filesystem. Such files just won't appear in search results and their thumbnails & quick previews will be empty. Note these commands will be run from within the container. 

### Tasks and Tools for MONTHLY MAINTENANCE
- Cleanup OS an host applications [_Bleachbit_](https://www.bleachbit.org/): Cleanup host OS filesystem, temp, cache, bin, old update files, old logs etc. Runs twice: normal and with elevated rights.
- Cleanup Docker images and dangling containers/volumes
- Update host OS, applications.
- Update docker images and containers
- Perform filesystem maintenance: balancing & scrubbing disks. Note for the backup disk, the monthly task is actually in the Nightly script, since the disk needs to be mounted, best to run monthly right after completing nightly backup. 

&nbsp;

### STEP 1: CONFIGURE MONTHLY
Ensure all your drives are listed under BTRFS filesystem maintenance. The correct paths to subvolumes and device names. 

### STEP 2: NIGHTLY (optional) 
If you need it, uncomment the sections that you need. Regarding Archiver:
- Verify the paths are correct in the 2 files in `HOST/archiver/`.
- Notice the exclude list, it excludes filerun hidden folders, this way your photo thumbnails/previews stay on your fast SSD. 
- The Filerun.sh file contains maintenance tasks that run globally for all users and tasks that can only be run per user. Replace `filerunuserX` for the correct usernames and copy these lines to run this task for all users. This task is necessary to create thumbnails and previews for files created outside of FileRun web environment or webDAV clients. 

### STEP 3: Test the Nightly and the Monthly. 
- Make sure you finished [Backup Guide](https://github.com/zilexa/Homeserver/tree/master/backup-strategy).
- Run the Nightly and the Monthly to check for errors/mistakes `sudo bash $HOME/docker/HOST/nightly.sh` and `sudo bash $HOME/docker/HOST/monthly.sh`. 
<sub>Note we only use sudo because it is required to create snapshots/backups. This is also why we use `sudo crontab` instead of `crontab` even though all other tasks do not need sudo. Using 2 different crontabs might cause running tasks to overlap. </sub>

### STEP 5. Schedule Nightly and Monthly
- In terminal (CTRL+ALT+T) open Linux scheduler`sudo crontab -e` and copy-paste the below into it. Make sure you replace the existing MAILTO and _do not_ fill in your emailaddress otherwise you will receive unneccesary emails, use `""` instead. Notice you should already have 1 line, for your backups. 
- If you use Nightly, change the btrbk-mail.sh to the Nightly script and paste this btrbk-mail line in your Nightly. 
```
MAILTO="youremail" #will only be used if crontab itself has an error
30 5 * * * /usr/bin/bash /home/$LOGUSER/docker/HOST/btrbk/btrbk-mail.sh          
50 5 * * 7 run-if-today L zo && /usr/bin/bash /home/$LOGUSER/docker/HOST/monthly.sh
*/5 * * * * su -l ${LOGUSER} -c 'docker exec -w /var/www/html/cron filerun php email_notifications.php drive.mydomain.com'

```
Note this means:
- Backups run 5.30 AM every day. Monthly runs every first Sunday of the month at 5.50AM. 
  - Feel free to change the schedule. [This calculator](https://crontab.guru/) will help you, additionally check how to use [run-if-today](https://github.com/xr09/cron-last-sunday/blob/master/run-if-today). 
  - If `btrbk-mail` or `Nightly` happens to still be running while Monthly is executed, Monthly pauses until it is done (see how the scripts start and end).  
<sub>The script creates a file "tasks-running" and deletes the file when the script is finished. The Monthly script checks if such a file exists, waits for it to disappear, then starts running its tasks :). </sub>
- See FileRun in [Configure Apps & Services](https://github.com/zilexa/Homeserver/blob/master/services-apps-configuration.md), the recommendation is to disable notifications to prevent users from being overfloaded with notifications for each file download/upload. For example, if someone downloads a folder with 1500 files, hundreds of emails could be sent out. With this task, notifications will only be sent out every 5 minutes. FileRun (and any other docker service) should never be run as root. <sub>This is why [the prep-server.sh file creates ${LOGUSER} env variable](https://github.com/zilexa/Homeserver/blob/8d422616bda84ef976ef60693f49335c527bd7f8/prep-server.sh#L91), because root cronjobs operate in a limited environment without variables that point to the regular user.</sub>



