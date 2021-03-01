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
 
## Scenario 1 With tiered caching via MergerFS pool.
How it works: MergerFS runs on top of the BTRFS disks in "user-space". It's flexible, you maintain direct disk access. 2 pools: one with, one without the SSD or cache folder. Nightly, data from the cache drive is copied to the pool without the cache folder. 
- You can use existing disks with data on it, in different sizes. BTRFS filesystem is recommended. Not required.
- Data is striped/smeared over disks: they will get filled more or less evenly. 
- If 1 disk fails, data on other disks is available like normal, via the pool or by accessing the disks individually.   
- New files will be created on the SSD cache drive or a specific folder on your system SSD drive if certain conditions are met (such as free space). 
- Files that haven't been modified for X days will be moved from the SSD to the disks within the pool. 
 
## Scenario 2 No MergerFS, no tiered caching: 2 options
You simply use BtrFS own pooling and you can choose whether you want traditional realtime mirroring or use SnapRAID for a more backup-like scheduled parity/mirroring.
- You cannot use an SSD as cache (BtrFS has no tiered caching support).
- You can use existing disks with data only if they were already BTRFS formatted.. 
- Recommended in this scenario is use the btrfs default way to pool drives, but you have 2 options:
  - **Option 1.Recommended: no realtime mirroring: _Stripe data_ (="spread in blocks over all the disks") _and mirror metadata_ across disks:**
    - When 1 disk fails, the array is still avaiable with data of the other disks but you can't restore the data via BtrFS options (no data mirroring). 
    - Instead, you protect against disk failure with SnapRAID: You need (at least) 1 dedicated parity disk per 4 data disks.
    - SnapRAID is scheduled to run nightly or every 6 hrs. Means you loose ability to restore data of the last 6hrs.
    - When data is written, only data disks will spin. This means the parity disk should have a longer lifecycle/wear down at a much slower pace.
  - **Option 2.BtrFS-Raid1: realtime mirroring: _Mirror both data and metadata_ across disks:** 
    - Data is mirrrored realtime to other disk in the pool: only half (!) of total disk space will be available for data. Use this only if you have plenty of disks.
    - When a disk fails, you can restore data via BtrFS.
    - There is no specific parity disk, so no need to distinguish between data and parity disks in your naming convention. 
    - When data is written, **all disks** will spin. This also means the disks will wear down more or less at the same pace.
- **For benefits of SnapRAID versus RAID1:** [please read the first 5 SnapRAID FAQ](https://www.snapraid.it/faq#whatisit). This is why, for home use instead of enterprise use I recommend no realtime mirroring. 

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
- Scenario 1 and 2-option1: create a single filesystem per disk: run `sudo mkfs.btrfs -f -L data1 –m single /dev/sda` for each disk device, with the right path. 
- Scenario2-option2: Single command to create a volume/array, add path to all disk devices (except backup disk) `sudo mkfs.btrfs -f -L data1 –d raid1 /dev/sda /dev/sdb`.
More commands and info about BtrFS can be found via the official doc or by Googling. I prefer this doc as [quick reference](https://docs.oracle.com/cd/E37670_01/E37355/html/ol_about_btrfs.html).

### Step 3: setup-storage.sh & adjust for your disks
Read this step fully before running the script.
The script will install tools, create the subvolume for Docker persistent volumes and a subvolume for OS drive backup purposes (system-snapshots). These are server specific, therefore not in the post-install script. The Docker subvolume will allow you to easily backup or migrate your Docker apps config/data and all maintenance scripts/tasks for the server.

#### For both scenarios: 
- *_EDIT LINE 40 FIRST!_* To reflect the # of drives you have (for data, parity and backup). 

#### Scenario 2 exceptions: 
- remove line 3-8: No need to install MergerFS.
- Remove line 39 as there is no /mnt/pool-archive folder necessary without MergerFS tiered cache.
- Mount your BTRFS1 array with the same arguments as a data disk in the example fstab.

### Step 4: unmount old mount points
- Go to Budgie menu, search DISKS, open it. 
- hit the STOP button for each disk, not the boot drive of course. Just to make sure there are no old mounts.
- Now run `sudo mount -a` to mount everything.

Congrats, your filesystem is now setup!
The combined data of your data disks should be in /mnt/pool and also (excluding the SSD cache) in /mnt/pool-archive. 
