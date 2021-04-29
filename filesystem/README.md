## STEP 1: A Modern Homeserver _filesystem_

# SYNOPSIS
Technologies used: 
- [BtrFS](https://linuxhint.com/btrfs-filesystem-beginner-guide/), an advanced filesystem. 
- [MergerFS](https://github.com/trapexit/mergerfs#description) Allows to add a fast cache to your drive pool. Explaination here: [Tiered Caching](https://github.com/trapexit/mergerfs#tiered-caching). This way, [you can choose to use](https://github.com/zilexa/Homeserver/blob/master/Hardware%20recommendations.md) small 2.5" disk drives with very low power consumption and don't worry about speed (disk speed is not very important in a homeserver anyway).  
- [SnapRAID](http://www.snapraid.it/faq#whatisit) via [Snapraid-btrfs](https://github.com/automorphism88/snapraid-btrfs#faq), reap the benefits for home use of SnapRAID-btrfs over BTRFS-RAID.
- [btrbk](https://github.com/digint/btrbk), the default tool (for BtrFS) for a wide variety of backup purposes.
- [nocache](https://github.com/Feh/nocache#nocache---minimize-filesystem-caching-effects)-rsync, to free up cache by moving data to the disks within the merged pool.
- hdparm and/or built in Disks tool of Ubuntu to configure drives to sleep after 15min & to make sure drives don't do too many load-cycles, keeps them healthy. 

## Why BtrFS?
- It is stable, used for years by major cloud providers and tech companies. It did get a bad reputation because of bugs in the past. Emphasis on past. In some consumber Linux distributions, it is the default filesystem. 
- It is extremely easy to use with regards to snapshots and subvolumes, supporting read-only snapshots for backups. 
- btrfs send/receive command allow for safe and very fast copying/backup of your data, with less physical effort from the harddisk components compared to rsync. 
- It does not require excessive (RAM) resources like ZFS. 
- Several benefits over EXT4 to protect data integrity and protect against disk read/write errors such as checksums and (meta)data redundancy.
- high compression capabilities to reduce the amount of data that needs to be written tot disk: maintain good speed, get max storage capacity. 
- Background scrub process to find and to fix errors on files with redundant copies: data integrity.
- Online filesystem defragmentation.
- Great for SSDs and HDDs.</details>

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

&nbsp;

# MODERN FILESYSTEM GUIDE
## Requirements: 
1. The OS disk should be BtrFS: [OS Installation](https://github.com/zilexa/Ubuntu-Budgie-Post-Install-Script/tree/master/OS-installation) shows how to do that.
2. Your system root folder `/` and `/home` folder should be root subvolumes. This is common practice for Ubuntu (Budgie) when you installed it on a BtrFS disk. 
3. With BtrFS it is highly recommended & common practice to create nested subvolumes for systemfolders `/tmp`  and `$HOME/.cache`. The `setup-storage.sh` (Step 2) will do that, plus a root subvolume, mounted at `$HOME/docker`. Check the file and remove the sections if you already have those subvolumes.

--> If you prefer Raid1, follow those steps and in step 3 notice steps marked "_Exception `Raid1`_" or "_Exception `Raid1` + SSD Cache_".\
--> Otherwise ignore those steps. 
### Step 1A: Identify your disks
Note this will delete your data. To convert EXT4 disks without loosing data or add existing BtrFS disks to a filesystem, Google. 
1. unmount all the drives you are going to format: for each disk `sudo umount /media/(diskname)` or use the Disks utility via Budgie menu and hit the stop button for each disk. 
2. list the disk devices: `sudo fdisk -l` you will need the paths of each disks (for example /dev/sda, /dev/sdb, /dev/sdc). 
3. Decide the purpose of each disk and their corresponding label, make notes (`data1`, `data2` etc. `backup1`, `parity1`). 
4. In the next steps, know `-L name` is how you label your disks. 

### STEP 1B: Create the permanent mount points
1. Create mount point for the pool: `sudo mkdir -p /mnt/pool`
2. For the SSD cache: to be able to unload the cache to the disks, also create a mountpoint excluding your cache`sudo mkdir -p /mnt/pool-nocache`. 
3. Create mount point for every disk at once: `sudo mkdir -p /mnt/disks/{cache,data1,data2,data3,parity1,backup1}` (change to reflect the # of drives you have for data, parity and backup.)

<details>
  <summary>### practical commands you might need before step 2A: wipe the disk, delete partitions</summary>
  
- To wipe the filesystems, run this command per partition (a partition is for example /dev/sda1 on disk /dev/sda): `sudo wipefs --all /dev/sda1`
- To delete the partitions: `sudo fdisk /dev/sda`, now you are in the fdisk tool. Hit `m`. You will see the commands available. Use `p` to show the list of partitions, `d` to delete them one by one, `w` to save changes. Then proceed with step 2A. 
- To list all subvolumes in your whole system: `sudo btrfs subvolume list /` or only of one mounted disk `sudo btrfs subvolume list /mnt/disks/data1`.
- To rename an existing subvolume, after mounting the disk, simply use `mv oldname newname`, feel free to use the full path.
- To delete subvolumes, `sudo btrfs subvolume delete /mnt/disks/data1/subvolname`. 
</details>

### STEP 2A: Create filesystems and root subvolumes
1. For the parity disk(s): Create ext4 filesystem with [snapraid's recommended options](https://sourceforge.net/p/snapraid/discussion/1677233/thread/ecef094f/): `sudo mkfs.ext4 -L parity1  -m 0 -i 67108864 -J size=4 /dev/sdX` _where X is the device disk name, see 1A_.
2. For each data and backup disk: Create btrfs filesystem `sudo mkfs.btrfs -f -L data1 /dev/sdX`.
3. For each data disk: Temporarily mount the disk like this: `sudo mount /dev/sdX /mnt/disks/data1`.
4. For each data disk: Create a root subvolume like this: `sudo btrfs subvolume create /mnt/disks/data1/data`.  

<details>
  <summary>### STEP 2B For Raid1 (click to expand)</summary>

1. Create 1 filesystem for all data+backup disks:  `sudo mkfs.btrfs -f -L pool –d raid1 /dev/sda /dev/sdb` for each disk device, set label and path accordingly (see output of fdisk).
2. For the backup disk, use the command in 2A. 
3. Do step 3 and 4 from 1C now, but obtaining the path of your array first via `sudo lsblk`. 
4. Modify the script:  
- Line 10-38 (Snapraid install): remove. Line 3-8 (MergerFS install): remove if you will not use an SSD cache with Raid1. 
- Line 49: remove. Line 48: Keep, as this is the path used by scripts and applications. 
- Line 50: Remove parity1 and remove data1-data3 between brackets { } because raid1 appears as a single disk, it will be mounted to `/mnt/pool`.
- _Exception `Raid1` + SSD Cache_: Add `raid1` between brackets { }. You  will mount the filesystem (in step 4) to `mnt/disks/raid1` and the pool stays `/mnt/pool`.
</details>

&nbsp;

### Step 3: Run the script & use the fstab example file
_Read the notes in this step first_
1. To run the script, `cd $HOME/Downloads` and run it via `bash setup-storage.sh`, follow the steps laid out during execution.\

_**Script notes:**_
- The script will install tools, create (on system disk) the subvolume for Docker persistent volumes and a subvolume for OS drive backup purposes (system-snapshots).
- **The script does everything for you except adding your disks to the systems mount config file (/etc/fstab), it helps you find them and copy them to the `fstab`file, which is a system file that tells the system how and where to mount your disks.**

_**Example fstab notes:**_
- There is a line for each system subvolume to mount it to a specific location.
- There is a line for each data disk to mount it to a location.
- There are commented-out lines for the `backup1` and `parity1` disks. They might come in handy and it's good for your reference to add their UUIDs. 
- For MergerFS, the 2 mounts contain many arguments, copy paste them completely. 
  - The first should start with the path of your cache SSD and all data disks (or the path of your raid1 pool) seperated with `:`, mounting them to `/mnt/pool`.
  - The second is identical except without the SSD and a different mount path: `/mnt/pool-nocache`. This second pool will only be used to periodically offload data from the SSD to the data disks. 
  - the paths to your ssd and disks should be identical to the mount points of those physical disks, as configured 

<details>
  <summary>fstab RAID1 exceptions (click to expand)</summary> 
- You only need 1 line for datadisks, with the single UUID of the raid1 filesystem and no line for parity.
- RAID1 + SSD cache: you only need the first MergerFS line (`/mnt/pool`), with the SSD path and the Raid1 path (/mnt/disks/raid1). Because /mnt/disks/raid1 is the path for cache unloading.
</details>

_**MergerFS Notes:**_
- The long list of arguments have carefully been chosen for this Tiered Caching setup.
- [The policies are documented here](https://github.com/trapexit/mergerfs#policy-descriptions). No need to change unless you know what you are doing.
- When you copy these lines from the example fstab to your fstab, make sure you use the correct paths of your data disk mounts, each should be declared separately with their UUIDs above the MergerFS lines (mounted first) just like in the example!

## Step 4: Mount the disks and pools!
1. Make sure all disks are unmounted first: `umount /mnt/disks/data1` for all mount points, also old ones you might have in /media.
2. Make sure each mount point is an empty folder after unmounting.
3. Automatically mount everything in fstab via `sudo mount -a`. If there is no output: Congrats!! Almost done!
4. Verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`. 

The combined data of your data disks should be in /mnt/pool and also (excluding the SSD cache) in /mnt/pool-nocache.

&nbsp;

### Good practices
**Harddisk power management**\
Some harddisks (Seagate) spindown/power down immediately when there is no activity, even if a standby timout of XX minutes has been set. This will wear out the disk _fast_.\
Via the Disks app, you can check disk properties and power settings. Note a value of 127 is common but also the culprit here. Changing it to 129 allows the standby timout to work:
```
sudo hdparm -S 240 -B 129 /dev/sdX
```
Perform this command for all your disks. Note 240 = standby after 20min, for 30 min timeout, use 241. 



Continue setting up your [Folder Structure](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure) or go back to the main guide. 
