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

## Use Btrfs data duplication? 2 options
BtrFS offers 3 ways to create a single fileystem across multiple devices, I only mention 2 here: 
- **BtrFS Single**: data is allocated to disks linearly, metadata is duplicated (`mkfs.btrfs -d single /dev/sda /dev/sdb /dev/sdc /dev/sdd`)
  - Pros: 
    - Maximum space available: disk size = available space.
    - Flexible: use disks of different sizes.
    - When 1 disk fails, the filesystem is recoverable (compared to raid0). 
  - Cons
    - When 1 disk fails, data from that disk is not recoverable.
    - When 1 disk fails, files larger than 1GB might have been partially stored on that disk. 
    - What files are stored on which disks is not obvious: especially blocks of a single file (>1GB) can be spread across disks. 
- **BtrFS Raid1**: data is striped and duplicated, metadata is duplicated (`mkfs.btrfs -d dup /dev/sda /dev/sdb /dev/sdc /dev/sdd`)
  - Pros
    - Data is mirrored on other disks in realtime, when a disk fails, the data is easily recoverable. 
    - The most secure method to store precious data. 
  - Cons
    - Expensive: you need twice the disks to get same amount as storage as Btrfs Single. 
    - Requirements around disk sizes because of duplication. 
    - All disks will be spinning for file access/write and because of duplication, disks can wear out at the same pace, which means if 1 fails it is statistically likely a second one will fail soon. 

## Option 3: individual filesystems, drives pooled via MergerFS
_A more home-friendly and economical solution:_
Instead of using any type of RAID, consider why that would be a default option? Your #1 goal is to have a single storage path, for all your data, regardless whether it is spread over multiple drives. For that, _RAID is not the default option_. Because this is called drive pooling. It is just an extra convenience of RAID. But you can also simply use a drive pooling tool, that only pools the drives into a single path! (while keeping them accessible seperatly). This tool is MergerFS. 

Reasons to use MergerFS:
1. You only need drive pooling.
2. MergerFS has a slight drawback in speed, this should not be an issue for most users. 
3. BTRFS Single is not secure enough for your personal data. 
4. BTRFS Raid1 isn't for everyone: You need twice the disks, this can be uneconomical. When your data grows >50% of disks you need more disks again. 
5. RAID (single/raid1) is not a backup. This means you still need other drives to store backups on. 

### Benefits of using individual drives, pooled through MergerFS:
- Drives each have _individual BtrFS_ filesystems: metadata is duplicated to help the filesystem recover itself from errors/corruption.. 
- Files are stored **as a whole** on disks, not spread out in blocks across multiple disks.
- 100% clarity which drive contains what file.  **see where (on which disk)** what files are stored and access them directly for recovery purposes.
- You can **combine whatever combination of disk sizes.**
- **No risk of losing files >1GB.**
- Disks don't all have to spin up for file access/write, **reducing disk load and power consumption, enhancing life cycle**.
- You choose whether data is balanced over the disks (writing data to disks with most free space) or stored linearly: fill up 1 disk before using the next. 
- Protecting against drive failure (like with raid1) can be done through SnapRAID! This will only cost you 1 disk per 4 disks. 

## Option 4: single disk, backup disks
- If your data does not fill much more than half of a single drive and the data does not grow fast, there is no need for data pooling. 
- Just make sure you have 1 or 2 backup drives inside your system. Also see the Backup Strategy Guide. 
- If you do need more storage in the future, you can always add a drive and enable MergerFS or convert the existing drive to BTRFS single or raid1. 


&nbsp;

## What should you choose? 
- it all depends on your personal situation. By default, start with drive pooling through MergerFS unless you have plenty of drives. 
- As a best practice your precious personal data (documents, photos, videos, music albums) should be on seperate drives from your downloaded media/download drive. 
- Note SnapRAID is only useful if you have more than 1 drive with data and is not practical to use in combination with a drive that has constantly changing data (like a download drive for your series/movies). 

### About snapraid/snapraid-btrfs
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
- This is NOT USEFUL if your datadrives are already SATA SSDs, since SATA SSDs are plenty fast for a NAS/homeserver. 

We use this solution because it is extremely easy to understand, to setup and to use and very safe! There is an alternative: bcache, which is a more advanced caching solution but comes with caveats. 

&nbsp;

Continue to the Filesystem Guide. 
