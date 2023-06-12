## Parity-based backup 
With SnapRAID, you can dedicate 1 or multiple drives to store a parity file. With 1 parity drive, you can protect up to 4 drives against a single drive failure. This makes it a very economic solution to protect multiple drives against drive failure without actually having a backup drive for each drive you want to protect. You can also add multiple parity drives.  
SnapRAID updates the parity on a set schedule. For example, daily or every X hours.
With SnapRAID-BTRFS (a wrapper for SnapRAID), the SnapRAID uses a snapshot of your subvolumes to create/update the parity file. Now, the live subvolumes data can be modified between updates, you will always be able to restore the last snapshot of the drive. 
With SnapRAID-BTRFS-Runner, you will get email notifications of the SnapRAID sync updates. 
- LIMITAION: you can only configure 1 subvolume per disk. If you store /Media and /Users on the same disk, the logical choice would be to protect /Users with SnapRAID. 
- If you plan to use SnapRAID, use it for your Users subvolumes or for the Media subvolumes (Movies, Shows, Music, Books) but not for the `incoming` folder, as that folders content change a lot, your snapshots will take up lots of space. 


### Step 1: Create snapper config files
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
See the [Maintenance Guide](https://github.com/zilexa/Homeserver/blob/master/Maintenance-guide). SnapRAID is run once a day via the [Nightly](https://github.com/zilexa/Homeserver/blob/master/docker/HOST/nightly.sh) script. But you can choose to run it more often, by adding it directly to cron.

Note the snapshots created specifically for SnapRAID are seperate from the snapshots created by btrbk [(see Backups-guide)](https://github.com/zilexa/Homeserver/tree/master/Backups-guide), which maintains a timeline (X days, X weeks, X months) and copies snapshots to backup drives. 
