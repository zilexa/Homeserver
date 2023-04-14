# STEP 7: Server Backup Guide
## [SYNOPSIS](https://github.com/zilexa/Homeserver/blob/master/backup-strategy/backupstrategy.md)
_(read the synopsis first)_

Contents:
  - [Prerequisities](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#prequisities)
  - [I. BTRFS subvolume backups](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#ii-configure-subvolume-backups-via-btrbk)
  - [II. Parity-based backups](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#i-configure-parity-based-backups-via-snapraid-btrfs)
  - [III. Auto-archiving to USB disk](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#iii-configure-auto-archiving-to-usb-disk-via-btrbk)
  - [IV. Ecrypted backups to a trusted online location](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#iv-configure-encrypted-backups-to-a-trusted-online-location-via-rclone)


### Prequisities
Necessary tools have been installed by prep-server.sh in [Step 1B:Install Essentials](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools).
- btrbk for scheduled snapshots and backups.
- snapraid/snapraid-btrfs/snapraid-btrf-runner for parity based protection of 1 subvolume per drive.
- Ready to use config files for btrbk and snapraid.
- A folder `/mnt/drives/system/snapshots` is created to store snapshots of the system drive. 

_All you have to do following the below steps:
- As root, create a folder `snapshots` in the root of each datadrive that contains `users` data (for example `/mnt/drives/data1/snapshots`). If not created as root, make sure root owns it `sudo chown root:root snapshots`.
- Give it limited permissions. Without root, you want read access to this folder, that way, you can easily restore from a snapshot: `sudo chmod 655 snapshots`.
- Tailor the `.conf` file of [btrbk](https://digint.ch/btrbk/) and optionally [snapraid](https://www.snapraid.it/), [snapraid-btrfs-runner](https://github.com/fmoledina/snapraid-btrfs-runner) to your needs, read their documentation.
- Run snapraid-btrfs-runner for the first time manually to create the parity file (on `mnt/disks/parity1)`. 
- Run btrbk for the first time manually to create the first snapshots and back those up to your backup drives (`mnt/disks/backup1`, `mnt/disks/backup2` etc). 


## I. BTRFS subvolume backups _via btrbk_
The btrbk config file has been carefully created and tested to:
- Create timestamped snapshots in the root of the disks, giving you a timeline view of your subvolumes in the `snapshots` folder of each disk :)
- Incremental backups will be sent to your internal backup disk, multiple disks can be added.
- Allows you to run a backup actions automatically and manually for multiple subvolumes by using groups. 
- Allows you to archive (copy) backups to BTRFS USB disks easily. 
_No other tool allows you to do all that automatically. The config file is also easy to understand and to adjust to your needs._  

### Step 1: Create the snapshot location and backup target location folders
- Create a `snapshots` folder in the root of each cache/data disk, for example `sudo mkdir /mnt/disks/data1/snapshots`
- In `/mnt/disks/backup1/`, create all destination folders for system and each data disk, for example via: `sudo mkdir /mnt/disks/backup1/{system,data1,data2,cache}`

### Step 2: Get the configuration & adjust settings, retention policy to your needs
- Open the file located in `$HOME/docker/HOST/btrbk/btrbk.conf`
- Read and understand the taxonomy, the order and the hierarchy. Change to your disk situation (verify paths of volumes, subvols, targets) Do not change the order or the indentation! 
- Edit the default retention policy used for data disks and the system-specific retention policy to your needs. Understand there are limits: if you create 10 snapshots of 1TB of data right now, it costs you 1TB in total. But when you start making big changes to your data and regular snapshots, this will cost lots of space as it deviates more and more from your oldest snapshot and backup. 

### Step 3: Run the backups!
When you think your btrbk.conf file is correct, do a dryrun, it will only perform a simulation: 
```
sudo btrbk dryrun -v
```
Read carefully the legenda and verify snapshots are created and backups are stored in the correct paths.  \
When all is well, run the same command without "-n" (simulation) and without -v (exessive info): 
```
sudo btrbk run --progress
```
BE AWARE this will perform all snapshot and backup actions, first time can take lots of time, after that, backups will be incremental.  \
Use this command if you ever want to initiate a backup run manually. Alternatively, you can also use this command to only backup a group of subvolumes, as configured in `btrbk.conf`. For example: `btrbk run users --progress `. 

### Step 4: Configure automatic backups
The `btrbk-mail.sh` script is from the official [btrbk repository](https://github.com/digint/btrbk) and will automatically mount backup drives, unmount when done and sent an email when an error has occured. You can easily edit that script to always sent an email. This script is included in the Nightly script that runs maintenance tasks, to be configured in the next guide: [Maintenance Guide](https://github.com/zilexa/Homeserver/tree/master/maintenance-tasks). 

1. Assuming you have entered your SMTP details during [Step 1B prep-server.sh](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools) otherwise do so first in `/etc/msmtprc` and replace `$DEFAULTEMAIL` with your email in `/etc/aliases`:  \
2. Edit the file `$HOME/docker/HOST/btrbk/btrbk-mail.sh` and: 
  - Change the email-subject to your server name or something you like. 
  - Make sure all required drives for running backups are listed in `mount_targets=`; 
      - Your system drive (`/mnt/drives/system`), at least 1 backup drive (`/mnt/drives/backup1`) and if not using MergerFS, your data drives (if you use MergerFS, you probably auto-mount these drives already). 
      - You should have added your backup drives in `etc/fstab` already during steps 3 and 5 of the [Filesystem guide](https://github.com/zilexa/Homeserver/tree/master/filesystem)

To run btrbk in the background and receive an email when done, run: `bash $HOME/docker/HOST/btrbk/btrbk-mail.sh`. Test if this works. \
Since it will be the second run, it should finish within a minute. If you ever want to initiate a backup run manually, use the command from the previous step instead of this one to show progress. 

Step 5: Schedule nightly backups
Run `sudo crontab-e` and copy the following: 
```
MAILTO="your email address"
30 5 * * * /usr/bin/bash /home/$LOGUSER/docker/HOST/btrbk/btrbk-mail.sh
```
More info about cron in the [Maintenance Guide](https://github.com/zilexa/Homeserver/tree/master/maintenance-tasks). 


&nbsp;

## II. Parity-based backups _via snapraid-btrfs_
#### Step 1: Create snapper config files
- Create a backup of the default template: `sudo mv /etc/snapper/config-templates/default /etc/snapper/config-templates/defaultbak`
- Get a template specific for Snapraid, disabling all other Snapper features: `sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapper/default`
- Now create snapper config files for the root filesystem: 
`sudo snapper create-config /`
- Create a snapper config for 1 subvolume per drive you want to protect with snapraid:  
`sudo snapper -c data1 create-config /mnt/disks/data1/Users`
- verify "timeline_create" is set to "no" in each file! 

### Step 2: Adjust snapraid config file
Open `/etc/snapraid.conf` in an editor and adjust the lines that say "ADJUST THIS.." to your situation. Note for each data disk, a snapper-config from the prev step must exist.

### Step 3: Test the above 2 steps.
Run `snapraid-btrfs ls` (no sudo!). Notice & verify 3 things: 
- A confirmation it found snapper configs for each(!) data disk in your snapraid.conf file. 
- A (correct) warning about non-existing snapraid.content files for each content-file location you defined in snapraid.conf, they will be automatically created during first sync. 
- A warning about UUIDs that cannot be used. Correct, because Snapraid will sync snapshots, not the actual subvolumes. Note you won't get this errror if you sync the live filesystem with `snapraid sync`, but the whole idea is to not do that, so that you can always recover files, even when the live filesystem has changed in the last 24 hrs.

### Step 4: Run the first sync!
Now run `snapraid-btrfs sync`. That is it! It can take a long while depending on the amount of data you have. Next runs only process incremental changes and go very fast. 

### Step 5: Configure mail notifications
A script exists that takes care of running the sync command, scrub data (verifies parity file), clean up all but the latest snapshots, log everything to file and send email notifications when done. 
- Modify `$HOME/docker/HOST/snapraid-btrfs-runner` section `[email]` to add your emailaddress, the "from" emailaddress corresponding with your smtp provider account and add the smtp provider server details:
- Run it to test it works: `python3 snapraid-btrfs-runner.py` This should run snapraid-btrfs sync just like in step 3 and send you an email when done. 

Note: compared to the default snapraid-btrfs-runner, I have replaced the `mail` command for `s-nail` otherwise you need to do a whole lot more configuration (Postfix) to support `mail` on your system. 


### Step 6: Schedule SnapRAID to run Nightly
See the [Maintenance Guide](https://github.com/zilexa/Homeserver/blob/master/maintenance-tasks/README.md). SnapRAID is run once a day via the [Nightly](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/nightly.sh) script. But you can choose to run it more often, by adding it directly to cron.

Note the snapshots created specifically for SnapRAID are seperate from the snapshots created by [I. BTRFS subvolume backups](https://github.com/zilexa/Homeserver/tree/master/backup-strategy#ii-configure-subvolume-backups-via-btrbk), which maintains a timeline (X days, X weeks, X months) and copies snapshots to backup drives. 

&nbsp;

## III. Configure auto-archiving to USB disk _via btrbk_
See https://digint.ch/btrbk/doc/readme.html, section "Example: Backups to USB Disk". 

## IV. Configure encrypted backups to a trusted online location _via rclone_
TBA
