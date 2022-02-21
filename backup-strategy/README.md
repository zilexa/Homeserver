# STEP 6: Server Backup Guide
## [SYNOPSIS](https://github.com/zilexa/Homeserver/blob/master/backup-strategy/backupstrategy.md)
_(read the synopsis first)_

Contents:
  - [Prerequisities](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#prequisities)
  - [I. Configure parity-based backups](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#i-configure-parity-based-backups-via-snapraid-btrfs)
  - [II. Configure subvolume backups](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#ii-configure-subvolume-backups-via-btrbk)
  - [III. Configure auto-archiving to USB disk](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#iii-configure-auto-archiving-to-usb-disk-via-btrbk)
  - IV. Configure encrypted backups to a trusted online location (to-do)


### Prequisities
All prequisities have been taken care of by the script from [Step 1B:Install Essentials](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools).
- This script installed the tools (btrbk for backups, snapraid/snapraid-btrfs/snapraid-btrf-runner for backups and additional tools) but more importantly also added configuration files (based on the tools default example) that are almost ready to use. The script downloaded them from this folder to your `$HOME/docker/HOST/` folder. 
- By storing these files outside of your OS system dir (`etc/system`) you have your entire configuration independent of OS and backupped as a whole (`HOME/docker`). The files are symlinked into the system folder.  

_All you have to do:_
- Make sure you have done [step 1B](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools), by running the script or executing the commands to install the tools yourself. 

## I. Configure parity-based backups _via snapraid-btrfs_
#### Step 1: Create snapper config files
- For SS only: create a backup of the default template: `sudo mv /etc/snapper/config-templates/default /etc/snapper/config-templates/defaultbak`
- For SS only: Get the modified template:   
`sudo wget -O /etc/snapper/config-templates/default https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/HOST/snapraid/snapper/default`
- Create snapper config files for the root filesystem and each subvolume (max 1 per disk) you want to protect with snapraid:  
`sudo snapper create-config /` \
`sudo snapper -c data1 create-config /mnt/disks/data1/Users`
- verify "timeline_create" is set to "no" in each file. 

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
- Modify `$HOME/docker/HOST/snapraid-btrfs-runner` section `[email]` to add your emailaddress, the "from" emailaddress corresponding with your smtp provider account and add the smtp provider server details:\
Run it to test it works: `python3 snapraid-btrfs-runner.py` This should run snapraid-btrfs sync just like in step 3 and send you an email when done. 
- Note: compared to the default snapraid-btrfs-runner, I have replaced the `mail` command for `s-nail` otherwise you need to do a whole lot more configuration (Postfix) to support `mail` on your system. 

&nbsp;

## II. Configure subvolume backups _via btrbk_
The btrbk config file has been carefully created and tested to:
- Create timestamped snapshots in the root of the disks, giving you a timeline view of your subvolumes in the `timeline` folder of each disk. 
- Incremental backups will be sent to your internal backup disk, multiple disks can be added.
- Allows you to run a backup actions manually for multiple subvolumes by using groups. 
- Allows you to archive (copy) backups to BTRFS USB disks easily. 
No other tool allows you to do all that automatically. The config file is also easy to understand and to adjust to your needs.\

### Step 1: Create the snapshot location and backup target location folders
- We need access to the OS disk filesystem root and the backup disk, mount both:
  - `sudo mount /mnt/disks/backup1` 
  - `sudo mount /mnt/system` 
- Create the folder to store snapshots of the OS disk: `sudo mkdir /mnt/system/timeline`
- Similarly, create a `.timeline` (note the dot) folder in the root of each cache/data disk, for example `sudo mkdir /mnt/disks/data1/.timeline`
- In `/mnt/disks/backup1/`, create all destination folders for system and each data disk, for example via: `sudo mkdir /mnt/disks/backup1/{system,data1,data2,cache}`

### Step 2: Get the configuration & adjust settings, retention policy to your needs
- Open the file located in `$HOME/docker/HOST/btrbk/btrbk.conf`
- Read and understand the taxonomy, the order and the hierarchy. Change to your disk situation (verify paths of volumes, subvols, targets) Do not change the order or the indentation! 
- Edit the default retention policy used for data disks and the system-specific retention policy to your needs. Understand there are limits: if you create 10 snapshots of 1TB of data right now, it costs you 1TB in total. But when you start making big changes to your data and regular snapshots, this will cost lots of space as it deviates more and more from your oldest snapshot and backup. 
- Edit the file `$HOME/docker/HOST/btrbk/btrbk-mail.sh` and: 1) change the email subject to your server name and 2) make sure the mount targets are correct, see the example fstab: you should have a mount for the backup disk and a mount for the btrfs-root of your system OS disk.  

### Step 3: Do a full run of all snapshots and backups
When you think your btrbk.conf file is correct, do a dryrun, it will only perform a simulation: 
`sudo btrbk -n run`
Read carefully the legenda and verify snapshots are created and backups are stored in the correct paths.  \
When all is well, run the same command without "-n".  \
BE AWARE this will perform all snapshot and backup actions, first time can take lots of time, after that, backups will be incremental. 

### Step 4: Restore a subvolume

&nbsp;

## III. Configure auto-archiving to USB disk _via btrbk_

## IV. Configure encrypted backups to a trusted online location _via rclone_
