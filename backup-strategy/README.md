# Server Backup Guide
## Read first: [Backup Strategy](https://github.com/zilexa/Homeserver/blob/master/backup-strategy/backupstrategy.md)

Contents:
  - [Prerequisities](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#prequisities)
  - [I. Configure parity-based backups](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#i-configure-parity-based-backups-via-snapraid-btrfs)
  - [II. Configure subvolume backups](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#ii-configure-subvolume-backups-via-btrbk)
  - [III. Configure auto-archiving to USB disk](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/README.md#iii-configure-auto-archiving-to-usb-disk-via-btrbk)
  - IV. Configure encrypted backups to a trusted online location (to-do)


### Prequisities
Necessary tools have been installed by prep-server.sh in [Step 1B:Install Essentials](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools).
- btrbk for scheduled snapshots and backups.
- snapraid/snapraid-btrfs/snapraid-btrf-runner for parity based protection of 1 subvolume per drive.
- Ready to use config files for btrbk and snapraid.
- A folder `/mnt/disks/systemdrive/timeline` is created to store snapshots of the system drive. 

_All you have to do:
- Create a folder `timeline` in the root of each datadrive (for example `/mnt/disks/data1/timeline`); at least the drives containing a `Users` subvolume. 
- Tailor the `.conf` files of snapraid, snapraid-btrfs-runner and btrbk to your needs.  
- Run snapraid-btrfs-runner for the first time manually to create the parity file (on `mnt/disks/parity1)`. 
- Run btrbk for the first time manually to create the first snapshots and back those up to your backup drives (`mnt/disks/backup1`, `mnt/disks/backup2` etc). 

## I. Configure parity-based backups _via snapraid-btrfs_
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
- Modify `$HOME/docker/HOST/snapraid-btrfs-runner` section `[email]` to add your emailaddress, the "from" emailaddress corresponding with your smtp provider account and add the smtp provider server details:\
Run it to test it works: `python3 snapraid-btrfs-runner.py` This should run snapraid-btrfs sync just like in step 3 and send you an email when done. 
- Note: compared to the default snapraid-btrfs-runner, I have replaced the `mail` command for `s-nail` otherwise you need to do a whole lot more configuration (Postfix) to support `mail` on your system. 

&nbsp;

## II. Configure subvolume backups _via btrbk_
The btrbk config file has been carefully created and tested to:
> - Create timestamped snapshots in the root of the disks, giving you a timeline view of your subvolumes in the `timeline` folder of each disk :)
> - Incremental backups will be sent to your internal backup disk, multiple disks can be added.
> - Allows you to run a backup actions automatically and manually for multiple subvolumes by using groups. 
> - Allows you to archive (copy) backups to BTRFS USB disks easily. 
> 
_No other tool allows you to do all that automatically. The config file is also easy to understand and to adjust to your needs._ 

### Step 1: Create the Snapshots destinations and Backup destinations folders
- Create a `timeline` (note the dot) folder in the root of each cache/data disk, for example `sudo mkdir /mnt/disks/data1/timeline`. Snapshots will be stored here. 
- In `/mnt/disks/backup1/`, create all destination folders for system and each data disk, for example via: `sudo mkdir /mnt/disks/backup1/{system,data1,data2,cache}`. Snapshots will be _sent_ here and become your backups. 

### Step 2: Get the configuration & adjust settings, retention policy to your needs
- Open the file located in `$HOME/docker/HOST/btrbk/btrbk.conf`
- Read and understand the taxonomy, the order and the hierarchy. Change to your disk situation (verify paths of volumes, subvols, targets) Do not change the order or the indentation! 
- Edit the default retention policy used for data disks and the system-specific retention policy to your needs. Understand there are limits: if you create 10 snapshots of 1TB of data right now, it costs you 1TB in total. But when you start making big changes to your data and regular snapshots, this will cost lots of space as it deviates more and more from your oldest snapshot and backup. 

### Step 3: Do a full run of all snapshots and backups
- When you think your btrbk.conf file is correct, do a dryrun, it will only perform a simulation:  \
```
sudo btrbk -n run
```
- Read carefully the legenda and verify snapshots are created and backups are stored in the correct paths.  \
- When all is well you are ready to snapshot all your configured subvolumes and back them up to your backup drive(s): 
```
sudo btrbk -n run
```
This can take quite some time depending on how much data you have. Subsequent runs will be much faster as metadata will be scanned and only changes will be part of the next snapshot. 

### Step 4: Configure automatic backups

1. If you haven't done this already, fill in your email address (the administrator of your server) in this systemfile:  
```
sudo nano /etc/aliases
```
2. Edit the file `$HOME/docker/HOST/btrbk/btrbk-mail.sh` and: 
  - Change the email-subject to your server name or something you like. 
  - Keep `mailto=default` to use what is set in the system (/etc/aliases) or change at will. 
  - Most importantly make sure all required drives for running backups are listed in `mount_targets=`; 
      - Your system drive (`/mnt/disks/systemdrive`) and at least 1 backup drive (`/mnt/disks/backup1`). 
      - This only works if these mountpoints are present in your /etc/fstab, done in steps 3 and 5 of the [Filesystem guide](https://github.com/zilexa/Homeserver/tree/master/filesystem). 

3. Run `bash $HOME/docker/HOST/btrbk/btrbk-mail.sh` to run btrbk and receive an email when it is done. Since this is the second run it should go very fast.  \
   Note this command will be used in the Nightly maintenance run (see next guide).  \
   If you ever need to do a manual run, it is better to use the `btrbk run` command, it shows the progress. 

&nbsp;

## III. Configure auto-archiving to USB disk _via btrbk_

## IV. Configure encrypted backups to a trusted online location _via rclone_
