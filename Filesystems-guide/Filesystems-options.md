To learn about Linux system folderstructure, standard subvolumes and tips for your folderstructure have a look at [Folderstructure Recommendations](https://github.com/zilexa/Homeserver/blob/master/filesystem/folderstructure-recommendations.md), which is independent of the filesystem options described below. 

## Filesystems Options
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


## Option 1: all your data easily fits on a single disk
- Easiest solution! 
- If your data does not fill much more than half of a single drive and the data does not grow fast, there is no need for RAID or data pooling. 
- Also no need for RAID or MergerFS pooling if you can clearly seperate data per drive and the data will never exceed the size of the drive, for example: media downloads on drive 0, personal files of users A and B on drive 1 and personal files of users C and D on drive 2. 
- In addition to the single data drive, you would want at least 1 backup drives inside your system. Also see [Step 7. Configure & Run Backups](https://github.com/zilexa/Homeserver#step-7---configure--run-backups). 
- If you do need more storage in the future, you can always add a drive and move to option 2. 

## Option 2: individual filesystems, drives pooled via MergerFS
_A more home-friendly and economical solution:_
- Instead of using any type of RAID, consider why that would be a default option? Your #1 goal is to have a single storage path, for all your data, regardless whether it is spread over multiple drives. For that, _RAID is not the default option_. Because 1) Linux already requires you to map physical drives to folders (you can map each drive to a subfolder). 
- Besides that, if you really need a single folder with multiple underlying drives (not subfolders), this is called _drive pooling_. It is just an extra convenience of RAID. But you can also simply use a drive pooling tool, that only pools the drives into a single path! (while keeping them accessible seperatly). This tool is MergerFS. 

Reasons to use MergerFS:
1. You only need drive pooling.
2. MergerFS has a slight drawback in speed, this should not be an issue for most users. 
3. BTRFS Single is not secure enough for your personal data. 
4. BTRFS Raid1 isn't for everyone: You need twice the disks, this can be uneconomical. When your data grows >50% of disks you need more disks again. 
5. RAID (single/raid1) is not a backup, even though raid1 can protect against single drive failure, there is a big chance both drives will fail as there is equal usage and wear. This means you still need other drives to store backups on. 

### Benefits of using individual drives, pooled through MergerFS:
- Drives each have _individual BtrFS_ filesystems: metadata is duplicated to help the filesystem recover itself from errors/corruption.. 
- Files are stored **as a whole** on disks, not spread out in blocks across multiple disks.
- 100% clarity which drive contains what file.  **see where (on which disk)** what files are stored and access them directly for recovery purposes.
- You can **combine whatever combination of disk sizes.**
- **No risk of losing files >1GB.**
- Disks don't all have to spin up for file access/write, **reducing disk load and power consumption, enhancing life cycle**.
- You choose whether data is balanced over the disks (writing data to disks with most free space) or stored linearly: fill up 1 disk before using the next. 
- Protecting against drive failure (like with raid1) can be done through SnapRAID! This will only cost you 1 disk per 4 disks. 

### Downsides of MergerFS
- This is basically an application in user-space. It is not a filesystem-level solution, instead runs on top of existing filesystems. This adds a layer of complexion and will affect read/write performance. 
- Creating backups of the drives is a bit more complicated, as you can only backup individual drives, but a folder could span across multiple drives. 

## Option 3: Use Btrfs data duplication?
BtrFS offers 3 ways to create a single fileystem across multiple devices, I only mention 2 here: 
- **BtrFS Single**: data is allocated to disks linearly, metadata is duplicated (`mkfs.btrfs -d single /dev/sda /dev/sdb /dev/sdc /dev/sdd`)
  - Pros: 
    - Maximum space available: disk size = available space.
    - Flexible: use disks of different sizes.
    - When 1 disk fails, the filesystem is recoverable (compared to raid0). 
  - Cons
    - When 1 disk fails, data from that disk is not recoverable.
    - When 1 disk fails, files larger than 1GB might have been partially stored on that disk. 
    - What files are stored on which disks is _not obvious_: especially blocks of a single file (>1GB) can be spread across disks. 
- **BtrFS Raid1**: data is striped and duplicated, metadata is duplicated (`mkfs.btrfs -d dup /dev/sda /dev/sdb /dev/sdc /dev/sdd`)
  - Pros
    - Data is mirrored on other disks in realtime, when a disk fails, the data is easily recoverable. 
    - The most secure method to store precious data. 
  - Cons
    - Expensive: you need twice the disks to get same amount as storage as Btrfs Single. 
    - Requirements around disk sizes because of duplication. 
    - All disks will be spinning for file access/write and because of duplication, disks can wear out at the same pace, which means if 1 fails it is statistically likely a second one will fail soon. You should ensure you have backups. See the Backups Guide. 

&nbsp;

## What should you choose? 
- Option 1 is definitely recommended. If you have too much data, consider Option 3 (simpler, but can be more expensive). 
- As a best practice your precious personal data (documents, photos, videos, music albums) should be on seperate drives from your downloaded media/download drive. 

### About snapraid/snapraid-btrfs
- Protection against disk failure [see backup subguide](https://github.com/zilexa/Homeserver/tree/master/maintenance) with dedicated parity disk(s) for scheduled parity, the disk will be less active than data disks, **extending its lifecycle** compared to the realtime duplication of Raid1.
- **For benefits of SnapRAID versus RAID1:** [please read the first 5 SnapRAID FAQ](https://www.snapraid.it/faq#whatisit) and note by using _snapraid-btrfs_ we overcome the single major [disadvantage of snapraid itself](https://github.com/automorphism88/snapraid-btrfs#q-why-use-snapraid-btrfs) (versus BtrFS-Raid1). Because these tools exist, I really recommend no realtime duplication for home use. 
- Note SnapRAID is only useful if you have more than 1 drive with data. 


### MergerFS BONUS: SSD tiered caching
This is NOT USEFUL if your datadrives are already SATA SSDs, since SATA SSDs are plenty fast for a NAS/homeserver  \
Optional read: [MergerFS Tiered Caching](https://github.com/trapexit/mergerfs#tiered-caching).  \
Short version:  \
MergerFS runs on top of the BTRFS disks in "user-space". It's flexible, you maintain direct disk access. We setup 2 disk pools: 1 with and 1 without the SSD. You will only use the first one. The 2nd is only used by the system to offload cache to the disks. 
- New files will be created on the SSD cache location (dedicated SSD or system SSD folder) but only if certain conditions are met (such as free space). 
- Files that haven't been modified for X days will be moved from the SSD to the disks within the pool. 
- In most cases, you won't hear your disks spinning the entire day, since everything you use frequently is on the SSD. 
- This CAN be used in combination with Raid1. 

We use this solution because it is extremely easy to understand, to setup and to use and very safe! There is an alternative: bcache, which is a more advanced caching solution but comes with caveats. 

&nbsp;

Continue to the [Filesystems Guide](https://github.com/zilexa/Homeserver/tree/master/Filesystems-guide).
