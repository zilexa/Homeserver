## A Modern Homeserver _filesystem_

Technologies used: 
- [BtrFS](https://linuxhint.com/btrfs-filesystem-beginner-guide/), an advanced filesystem. 
- [MergerFS](https://github.com/trapexit/mergerfs#description) Allows to add a fast cache to your drive pool. Explaination here: [Tiered Caching](https://github.com/trapexit/mergerfs#tiered-caching). This way, [you can choose to use](https://github.com/zilexa/Homeserver/blob/master/Hardware%20recommendations.md) small 2.5" disk drives with very low power consumption and don't worry about speed (disk speed is not very important in a homeserver anyway).  
- [SnapRAID](http://www.snapraid.it/faq#whatisit) via [Snapraid-btrfs](https://github.com/automorphism88/snapraid-btrfs#faq), reap the benefits for home use of SnapRAID-btrfs over BTRFS-RAID.
- [btrbk](https://github.com/digint/btrbk), the default tool (for BtrFS) for a wide variety of backup purposes.
- [nocache](https://github.com/Feh/nocache#nocache---minimize-filesystem-caching-effects)-rsync, only for a specific task (see MergerFS Tiered Caching).  
- hdparm and/or built in Disks tool of Ubuntu to configure drives to sleep after 15min & to make sure drives don't do too many load-cycles, keeps them healthy. 

Why BtrFS? 
- It is stable, used for years by major cloud providers and tech companies. It did get a bad reputation because of bugs in the past. Emphasis on past. In some consumber Linux distributions, it is the default filesystem. 
- It is extremely easy to use with regards to snapshots and subvolumes, supporting read-only snapshots for backups. 
- It does not require excessive (RAM) resources like ZFS. 
- Several benefits over EXT4 to protect data integrity and protect against disk read/write errors such as checksums and (meta)data redundancy.
- high compression capabilities to reduce the amount of data that needs to be written tot disk: maintain good speed, get max storage capacity. 
- Background scrub process to find and to fix errors on files with redundant copies: data integrity.
- Online filesystem defragmentation.
- Great for SSDs and HDDs.

## Use Btrfs data duplication? 2 options.
BtrFS offers 3 ways to create a single fileystem across multiple devices, I only mention 2 here: 
- **BtrFS Single**: data is striped (not duplicated), metadata is duplicated. 
  - Pros: 
    - Flexible: use disks of different sizes.
    - Available space: maximise the available space for data (compared to raid1).
    - When 1 disk fails, the filesystem is recoverable (compared to raid0).
  - Cons
    - When 1 disk fails, data from that disk is not recoverable.
    - When 1 disk fails, files larger than 1GB might have been partially stored on that disk. 
    - Where, on which disks files are stored exactly is unknown: blocks of a single file (>1GB) can be spread across disks. 
- **BtrFS Raid1**: data is striped and duplicated, metadata is duplicated. 
  - Pros
    - Data is mirrored on other disks in realtime, when a disk fails, the data is easily recoverable. 
    - The most secure method to store precious data. 
  - Cons
    - It costs more: only half of the total storage space is available for data, because of duplication. Use only if you have plenty of disks.
    - requirements around disk sizes because of duplication. 
    - All disks will be spinning for file access/write and because of duplication, disks can wear out at the same pace, which means if 1 fails it is statistically likely a second one will fail soon. 

## The alternative, economical home-friendly method
The default solution in this guide doesn't use BtrFS to pool disks into 1 filesystem, although Raid1 is optionally explained in the steps below. 
2 reasons: 
1. BtrFS Single pool is not secure enough for your personal data. 
2. Raid1 isn't for everyone: You need twice the disks, this can be uneconomical. When your data grows >50% of disks you need more disks again. 

### Coupled with MergerFS:
- Disks each have _individual BtrFS Single_ filesystems: metadata is duplicated, **disk can recover its filesystem by itself**. 
- Files are stored **as a whole** on disks, not spread out in blocks across multiple disks.
- You can always **see where (on which disk)** what files are stored and access them directly for recovery purposes.
- You can **combine whatever combination of disk sizes.**
- **No risk of losing files >1GB.**
- Disks don't all have to spin up for file access/write, **reducing disk load and power consumption, enhancing life cycle**.
- Disks become **more or less evenly full**, as files are written to the disk with the most free space (and you can balance manually). 

### Coupled with snapraid/snapraid-btrfs
- Protection against disk failure [see backup subguide](https://github.com/zilexa/Homeserver/tree/master/maintenance) with dedicated parity disk(s) for scheduled parity, the disk will be less active than data disks, **extending its lifecycle** compared to the realtime duplication of Raid1.
- **For benefits of SnapRAID versus RAID1:** [please read the first 5 SnapRAID FAQ](https://www.snapraid.it/faq#whatisit) and note by using _snapraid-btrfs_ we overcome the single major [disadvantage of snapraid itself](https://github.com/automorphism88/snapraid-btrfs#q-why-use-snapraid-btrfs) (versus BtrFS-Raid1). Because these tools exist, I really recommend no realtime duplication for home use. 

### MergerFS BONUS: SSD tiered caching
Optional read: [MergerFS Tiered Caching](https://github.com/trapexit/mergerfs#tiered-caching).  
Short version: 
MergerFS runs on top of the BTRFS disks in "user-space". It's flexible, you maintain direct disk access. We setup 2 disk pools: 1 with and 1 without the SSD. You will only use the first one. The 2nd is only used by the system to offload cache to the disks. 
- New files will be created on the SSD cache location (dedicated SSD or system SSD folder) but only if certain conditions are met (such as free space). 
- Files that haven't been modified for X days will be moved from the SSD to the disks within the pool. 
- In most cases, you won't hear your disks spinning the entire day, since everything you use frequently is on the SSD. 
- This CAN be used in combination with Raid1. 

We use this solution because it is extremely easy to understand, to setup and to use and very safe! There is an alternative: bcache, which is a more advanced caching solution but comes with caveats. 


## Requirements: 
1. The OS disk should be BtrFS: [OS Installation](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script/tree/master/OS-installation) shows how to do that.
2. Highly recommended: subvolumes on the OS disk. This can be done with my OS [post-install script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script). If you don't use that script, create these subvolumes yourself please. The script contains clear comments how its done, copy/paste the commands.
Check your system drive subvolumes via `btrfs subvolume list /` \
`@` (mounted at /)\
`@home` (mounted at /home)\
`@home/.cache` (nested subvolume /home/.cache)\
`@/tmp` (nested subvolume /tmp)

&nbsp;

--> If you prefer Raid1, skip 1A and 2A, do 1B, 2B instead and notice steps marked "_Exception `Raid1`_" or "_Exception `Raid1` + SSD Cache_".\
--> Otherwise ignore those steps. 
## Step 1: Prep your disks with a filesystem
Note this will delete your data. To convert EXT4 disks without loosing data or add existing BtrFS disks to a filesystem, Google. 
- unmount all the drives you are going to format: for each disk `sudo umount /media/(diskname)`
- list the disk devices: `sudo fdisk -l` you will need the paths of each disks. 
- Decide which disk(s) will be the `backup1` disk and for 2A which will be the `parity1`disk. 
- In the next steps, know `-L name` is how you label your disks. 

### 1A: Make filesystems
- Create a filesystem per disk: run `sudo mkfs.btrfs -f -L data1 /dev/sda` for each disk device, set label and path accordingly (see output of fdisk).
- Do the same for the parity disk with label `parity1` and backup disk with label `backup1`. 
- Via this naming scheme you can add/replace disks easily and combine scheduled backup tasks with temporarily USB attached disks. 

### 1B: For Raid1
- Create 1 filesystem for all data+parity disks (no dedicated parity drive):  `sudo mkfs.btrfs -f -L pool –d raid1 /dev/sda /dev/sdb` for each disk device, set label and path accordingly (see output of fdisk).
- For the backup disk, use the command in 2A. 


## Step 2: Add # of disks to setup-storage.sh
### 2A: add # disks
- All you have to do is change the labels betweeen brackets { } on [line 40](https://github.com/zilexa/Homeserver/blob/48cd734f453ddff1ed63cfb61047af6cb96b4d1e/filesystem/setup-storage.sh#L40) to reflect the # of drives you have for data, parity and backup.  That's it!\
\
Notes:\
--> The script will install tools, create the subvolume for Docker persistent volumes and a subvolume for OS drive backup purposes (system-snapshots).\
--> These are server specific, in addition to subvolumes created by the [Ubuntu Budgie post-install script](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script). The Docker subvolume will allow you to easily backup or migrate your Docker apps config/data and all maintenance scripts/tasks for the server.\
--> **The script does everything for you except adding your disks UUIDs, it helps you find them and copy them to the `fstab`file, which is a system file that tells the system how and where to mount your disks.**\
--> The script does not add your disks to that system file!\
--> Instead, use the example fstab file and copy the lines yourself _when the script asks you to_.\

### 2B For Raid1
- Line 10-28 (Snapraid install): remove. Line 3-8 (MergerFS install): remove if you also don't need SSD cache with Raid1. 
- Line 39: remove. Line 38: Keep, as this is the path used by scripts and applications. 
- Line 40: Remove parity1 and remove data1-data3 between brackets { } because raid1 appears as a single disk, it will be mounted to `/mnt/pool`.
- _Exception `Raid1` + SSD Cache_: Add `raid1` between brackets { }. You  will mount the filesystem (in step 4) to `mnt/disks/raid1` and the pool stays `/mnt/pool`.

## Step 3: Run the script & use the fstab example file
_Read this step fully first_\
Only 1 action: From the folder where you downloaded the script, run it (no sudo) via `bash setup-storage.sh`, follow the steps laid out during execution.
Have a look at the example fstab file. Notice: 
- There is a line for each system subvolume to mount it to a specific location.
- There is a line for each data disk to mount it to a location.
  - _Exception `Raid1`_: you only need 1 line, with the single UUID of the raid1 filesystem and no line for parity.
- There are commented-out lines for the `backup1` and `parity1` disks. They might come in handy and it's good for your reference to add their UUIDs. 
- For MergerFS, the 2 mounts contain many arguments, copy paste them completely. 
  - The first should start with the path of your cache SSD and all data disks (or the path of your raid1 pool) seperated with `:`, mounting them to `/mnt/pool`.
  - The second is identical except without the SSD and a different mount path: `/mnt/pool-archive`. This second pool will only be used to periodically offload data from the SSD to the data disks. 
  - the paths to your ssd and disks should be identical to the mount points of those physical disks, as configured 
  - _Exception `Raid1` + SSD cache_: you only need the first MergerFS line (`/mnt/pool`), with the SSD path and the Raid1 path (/mnt/disks/raid1). Because /mnt/disks/raid1 is the path for cache unloading.

#### MergerFS Notes:
--> The long list of arguments have carefully been chosen for this Tiered Caching setup.\
--> [The policies are documented here](https://github.com/trapexit/mergerfs#policy-descriptions). No need to change unless you know what you are doing.\
--> When you copy these lines from the example fstab to your fstab, make sure you use the correct paths of your data disk mounts, each should be declared separately with their UUIDs above the MergerFS lines (mounted first) just like in the example!

## Step 4: Mounting the disks according to the updated fstab file
First we have to _unmount old mount points_ and you should _verify the new mount points are EMPTY FOLDERS:_
- Go to Budgie menu, search DISKS, open it. 
- hit the STOP button for each disk, not the boot drive of course. Just to make sure there are no old mounts.
- Check all newly created mount points (folders) in `/mnt/disks`, each folder (for example `/mnt/disks/data1`, `/mnt/pool`) should be empty!
- Now run `sudo mount -a` to mount everything.

If there is no output: Congrats, your filesystem is now setup!
The combined data of your data disks should be in /mnt/pool and also (excluding the SSD cache) in /mnt/pool-archive. 

Continue setting up your [Folder Structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure) or go back to the main guide. 
