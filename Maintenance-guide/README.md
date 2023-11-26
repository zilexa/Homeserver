## Unattended, Automatic Maintenance

To keep your server spinning and purring everyday like its very first day, several tasks should be executed automatically on a regular basis.  
Below the tasks are explained. Note the order of execution has been chosen carefully. If you remove/add tasks, keep that in mind. Also note, depending on your setup and hardware, *all the tasks in Nightly.sh are optional.*

The prep-server.sh script has downloaded the tools and scripts to `$HOME/docker/HOST/`. Most importantly: 
- Automatic backups every morning: This is already covered in the [BTRFS subvolume Backups Guide](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#ii-configure-subvolume-backups-via-btrbk)
- Automatic Maintenance every last Sunday of the month: [/docker/HOST/monthly.sh](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/monthly.sh)
- Optional nightly tasks: [/docker/HOST/nightly.sh](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/nightly.sh)

***
### The Monthly Maintenance Email
Perhaps the cherry on the pie of this guide: The Monthly tasks are executed unattendedly, automatically and a nice email will be generated: 
- Informing you if a reboot is needed (eg. requiring you to take action)
- Overview of available storage space per filesystem (OS drive, Media, Users) and per Filerun user (subvolume). 
- Summary of performed tasks: 
    1. Cleanup (Host OS & apps, docker images/containers/volumes)
    2. Updates (Host OS & apps, docker images & container recreation)
    3. BTRFS Filesystem maintenance. 

This means absolute minimum amount of manual maintenance required! 
***

### STEP 1: CONFIGURE & TEST Monthly
1. Ensure all your drives are listed under BTRFS filesystem maintenance. The correct paths to subvolumes and device names. 
2. Assuming you have entered your SMTP details during [Step 1B prep-server.sh](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools) otherwise do so first in `/etc/msmtprc` and replace `$DEFAULTEMAIL` with your email in `/etc/aliases`:  \
Run `sudo bash $HOME/docker/HOST/monthly.sh`. All tasks should be performed and you should receive an email.

### STEP 2: SCHEDULE Monthly
You already scheduled the backups in [BTRFS subvolume Backups Guide](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#ii-configure-subvolume-backups-via-btrbk). Now all you have to do is add a line for monthly, using `run-if-today` to only run the Last Sunday of the month: 
```
sudo crontab -e
```
Copy & paste the below, For run-if-today to know what weekday you want to run it, You might need to change `su` (English short for Sunday) to your language 2-letter short for Sunday. Run this command to see what your system uses for today: `date +%a` and adjust accordingly:

```
30 5 * * * /usr/bin/bash /home/${LOGUSER}/docker/HOST/btrbk/btrbk-mail.sh
45 5 * * * . /etc/profile; run-if-today L su && su -l ${LOGUSER} -c '/usr/bin/bash $HOME/docker/HOST/monthly.sh'
*/5 * * * * . /etc/profile; su -l ${LOGUSER} -c 'docker exec -w /var/www/html/cron filerun php email_notifications.php drive.mydomain.com'
```
Hit CTRL+S to save and CTRL+X to exit.

This is your full and final cron, including the line for [backups](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#ii-configure-subvolume-backups-via-btrbk) and for FileRun notifications see [(FileRun "Required Configuration")](https://github.com/zilexa/Homeserver/blob/master/services-apps-configuration.md#files-cloud-via-filerun---documentation-and-support_).  \
This cron means:
- Backups run 5.30 AM every day. Monthly runs every first Sunday of the month at 5.50AM. FileRun notifications are sent every 5min.
- The Monthly will check if `btrbk` or `Nightly` are still running. if so, it will pause until they are finished.
- Feel free to change the schedules. [This calculator](https://crontab.guru/) will help you, additionally check how to use [run-if-today](https://github.com/xr09/cron-last-sunday).


&nbsp;

Congratulations, you finished this Guide ! 

&nbsp;

***
### Manual Maintenance
Only required if:
- The Monthly Email asks you to reboot --> go and reboot. If you do this via SSH, remember you still need to login.
- The Monthly Email shows you are hitting your storage limit --> tell users to cleanup or replace/add drives.
- The Monthly Email shows scrub errors for a certain filesystem --> follow steps here: TBA
- Besides the Monthly Email, your server will also email you if your drives are starting to get old. For this purpose, *smartd* is enabled, regularly performing S.M.A.R.T. tests for your storage drives and monitoring drive temperature. An email will be sent if drive S.M.A.R.T. values change or if a drive temperature is rising above 60 C. While this email might contain errors for certain drives, best is to Google those errors and see if it can be ignored. 
- You want to update to a newer Linux Kernel: Apps Menu > Manjaro Settings > Kernel > select the latest "LTS" version, install and reboot.  \
<sub>Every LTS ("Long Term Support") Kernel receives (security) updates for years. No need to upgrade to a newer kernel version regularly. But LTS versions are not released regularly anyway. Very new hardware (think: new laptops) will benefit from better drivers/hardware support using the latest "recommended" kernel instead of "LTS" kernel. BTRFS filesystem improvements also come with some kernel versions. For a server, always choose "LTS" version, not necessarily the latest "recommended" version.</sub>

***

&nbsp;

### OPTIONAL TASKS: Nightly maintenance
The Nightly script contains tasks only relevant if you need to perform several tasks every night. For example  1) use MerferFS with caching, 2) use parity based backups 3) modify user files outside of FileRun realm: 

- [_Archiver_](https://github.com/trapexit/mergerfs#time-based-expiring): If you use MergerFS SSD cache: Unload SSD cache: move _Users_ files unmodified for >30 days to harddisk array (from /mnt/disks/ssd to /mnt/pool-nocache). Since `/mnt/pool-nocache` = `/mnt/pool` without the SSD, the path to the moved files stays is the same, they are still in `/mnt/pool`, they are only moved to a different underlying disk. 
    - Exceptions to this task: Keep thumbnails created by FileRun and DigiKam (photo management software) on the SSD, for performance and power consumption purposes (the HDDs won't turn on when you scroll through your photos via FileRun). 
    - Also do not move files moved to trash.
    - do not attempt to move btrfs read-only snapshots.  
- _Filerun tasks_: Apart from cleanup, these tasks are only necessary when adding/deleting/modifying files/folders _outside_ of the filerun WebUI or connected WebDAV apps. Without running these tasks, you will _still_ see the files in FileRun and webDAV apps just fine, since FileRun simply shows you a realtime view of your filesystem. Such files just won't appear in search results and their thumbnails & quick previews will be empty. Note these commands will be run from within the container. 

#### Step 1. CONFIGURE & TEST Nightly
If you need the Nightly, uncomment the sections you need. The backup section is always required because it will run via Nightly instead of directly in cron (see below).  \
Regarding Archiver:
- Verify the paths are correct in the 2 files in `HOST/archiver/`.
- Notice the exclude list, it excludes filerun hidden folders, this way your photo thumbnails/previews stay on your fast SSD. 
- The Filerun.sh file contains maintenance tasks that run globally for all users and tasks that can only be run per user. Replace `filerunuserX` for the correct usernames and copy these lines to run this task for all users. This task is necessary to create thumbnails and previews for files created outside of FileRun web environment or webDAV clients. 
- Run the Nightly manually at least once: `sudo bash $HOME/docker/HOST/nightly.sh` 

#### Step 2. SCHEDULE Nightly
- Open crontab: `sudo crontab -e`
- See the example above, replace `/btrbk/btrbk-mail.sh` for `/nightly.sh`. 

