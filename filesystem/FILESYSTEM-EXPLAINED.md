## SYNOPSIS
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

Continue to the Filesystem Guide. 
