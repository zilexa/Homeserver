## A Modern Homeserver _filesystem_

Technologies used: 
- [BtrFS](https://linuxhint.com/btrfs-filesystem-beginner-guide/), the most advanced filesystem. 
- [MergerFS](https://github.com/trapexit/mergerfs#description) (optionally/recommended) if you want to add a fast cache to your drive pool. Explaination here: [Tiered Caching](https://github.com/trapexit/mergerfs#tiered-caching). This way, [you can choose to use](https://github.com/zilexa/Homeserver/blob/master/Hardware%20recommendations.md) small 2.5" disk drives with very low power consumption and don't worry about speed (disk speed is not very important in a homeserver anyway).  
- [SnapRAID](http://www.snapraid.it/faq#whatisit) via [Snapraid-btrfs](https://github.com/automorphism88/snapraid-btrfs#faq), reap the benefits for home use of SnapRAID-btrfs over BTRFS-RAID.
- [btrbk](https://github.com/digint/btrbk), the default tool (for BtrFS) for a wide variety of backup purposes.
- [nocache](https://github.com/Feh/nocache#nocache---minimize-filesystem-caching-effects)-rsync, only for a specific task (see MergerFS Tiered Caching).  
- hdparm and/or built in Disks tool of Ubuntu to configure drives to sleep after 15min & to make sure drives don't do too many load-cycles, keeps them healthy. 

Why BtrFS? 
- It is stable, used for years by major cloud providers and tech companies. It did get a bad reputation because of bugs in the past. Emphasis on past. In some consumber Linux distributions, it is the default filesystem. 
- It is extremely easy to use with regards to snapshots and subvolumes, supporting read-only snapshots for backups. 
- It does not require excessive (RAM) resources like ZFS. 
- Checksums on data and metadata (bitrot-prevention): essential for data integrity. Ext4 only has metadata integrity.
- Use top-notch assembler implementations to compute the RAID parity, always using the best known RAID algorithm and implementation.
- Several great compression options to maintain speed, get max storage capacity or well-balanced options (zstd:3). 
- Background scrub process to find and to fix errors on files with redundant copies: data integrity.
- Online filesystem defragmentation
- Great for SSDs and HDDs.

Downsides: 
- minimally slower, but this will be unnoticeable for our use case. 
- No support for a cache drive, solved by using MergerFS for pooling instead of BtrFS features for pooling. In this case, the drives will be formatted as BtrFS single. When BcacheFS (potential BtrFS successor) is released, the MergerFS solution is probably not necessary anymore. 
 

### Adding an SSD as cache for the data disk pool
If your boot drive is large enough, you can use a folder on it for caching of your data drives. If you have a secondary SSD, you can dedicate that one fully.
Please read about [MergerFS Tiered Caching](https://github.com/trapexit/mergerfs#tiered-caching) solution. We use this solution because it is extremely easy to understand, to setup and to use. BtrFS does not support tiered caching by itself. MergerFS can run atop any filesystem to create a simple union of your drives. 
 
## Scenario 1 With a cache
- You can use existing disks with data on it, in different sizes. BTRFS filesystem is recommended. Not required.
- new files will be created on the SSD cache drive or folder (instead of the data disks pool) if certain conditions are met (such as free space). 
- Files that haven't been modified for X days will be moved to the data disks pool. 
- MergerFS runs on top of the BTRFS disks in "user-space". It's flexible, you maintain direct disk access. 2 pools: one with, one without the SSD or cache folder. Nightly, data from the cache drive is copied to the pool without the cache folder. 

## Scenario 2 Without a cache: multiple choices
- You can use existing disks with data only if they were already BTRFS formatted.
- New files always go to the data disks pool. You don't need MergerFS, you can create a BTRFS filesystem that spans disks. 
- Recommended to use the btrfs default:
Default (with SnapRAID): Stripe the data and mirror the file system metadata across several devices: Use part of the space for data (since metadata is mirrored). 
Raid0 (with SnapRAID): Stripe both the file system data and metadata across several devices: use all space for data (no mirroring). 
RAID1: Mirror both the file system data and metadata across several devices: use half of the total space for data (since everything is mirrored). 
- Pick your evil. RAID1 is most secure but only useful if you have plenty of disks. Otherwise, go for default or RAID0.
- For benefits of SnapRAID versus RAID1: [please read the first 5 SnapRAID FAQ](https://www.snapraid.it/faq#whatisit). 

### Step 1: 
After installation and after running the [post-install script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script), your drive should already has a few subvolumes. If you don't use that script, create these subvolumes yourself please. 
Check this via `btrfs subvolume list /`
@ (mounted at /)
@home (mounted at /home)
@home/.cache (mounted at /home/.cache)
@/tmp (mounted at /tmp)

### Step 2: Create new filesystems for disks
Note this will delete your data. To convert EXT4 disks or add existing BtrFS disks to a filesystem, Google. 
- unmount all the drives you are going to format: `sudo umount /media/(diskname)`
- list the disk devices: `sudo fdisk -l`
- Scenario1: create the filesystem for each disk, do not use paritions (no numbers such as sda1): `sudo mkfs.btrfs -f -L data1 –m single /dev/sda`
- Scenario2 default: `sudo mkfs.btrfs -f -L data1 –m single /dev/sda`
- Scenario2 Raid0: `sudo mkfs.btrfs -f -L data1 –m raid0 /dev/sda`
- Scenario2 Raid0: `sudo mkfs.btrfs -f -L data1 –d raid1 /dev/sda`
More commands and info about BtrFS can be found via the official doc or by Googling. I prefer this doc as [quick reference](https://docs.oracle.com/cd/E37670_01/E37355/html/ol_about_btrfs.html).

### Step 3: setup-storage.sh & adjust for your disks
Don't just run the script! Open it in Pluma or other text editor. Read the comments. 
The script will install tools, create mount point folders and create the recommended subvolumes for Docker (to backup seperately and to "go back in time" with Docker containers) and a subvolume for OS drive backup purposes (system-snapshots). These are server specific, therefor not in the post-install script.

#### For both scenarios: 
- Expand the command that creates the disk mount points: data1, data2..., parity1, parity2...,backup1, backup2 ... etc to reflect the # of drives you have. 

#### Scenario 2 specific steps: 
- remove the part that installs MergerFS
- Remove the command that creates /mnt/pool (already created in step 2) and /mnt/pool-archive. 

### Step 4: 
- Run the script, when finished the script opens /etc/fstab file, this file contains all disks mounted at boot. You must fill in the UUIDs for all mounts. Easy for the OS drive as you can copy paste and save the file. 
- Open Pluma, new empty file. Run `blkid` command to get the UUIDs of all drives. Copy paste them in Pluma. 
- Run `sudo nano /etc/fstab`, copy paste the correct UUID per mount. 
- This means, you will choose which physical disks will be mounted as "data1", "data2", "parity1" and "backup1" in /mnt/disks. If you have more drives, copy paste & add them. 
- If using MergerFS, make sure the first part of each MergerFS line contains all your data disks and no parity/backup disk. Make sure the first MergerFS mount also contains the cache disk or cache folder. 
- save the file. 

### Step 5: unmount old mount points
- Go to Budgie menu, search DISKS, open it. 
- hit the STOP button for each disk, not the boot drive of course. Just to make sure there are no old mounts.
- Now run `sudo mount -a` to mount everything.

Congrats, your filesystem is now setup!
The combined data of your data disks should be in /mnt/pool and also (excluding the SSD cache) in /mnt/pool-archive. 
