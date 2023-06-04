# Guide: A Modern Homeserver _filesystem_ 

# SYNOPSIS: [Filesystem Options](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-OPTIONS.md)
_Read the Synopsis before continuing with this guide, to understand what you are about to do._

## Requirements: 
1. The OS disk should be BtrFS, this should be chosen during [OS Installation](https://github.com/zilexa/manjaro-gnome-post-install). 
2. You have ran the prep-docker.sh script and the server tools have been installed. 
3. You have read the synopsis, had a good night rest and are ready to decide which of the 3 options is best for you!

&nbsp;


## General need-to-knows
- In Linux, every piece of hardware has its own path starting with `/dev/...` For example, SATA drives are listed as `/dev/sda/` the next drive `/dev/sdb/` and so on. Partitions will be `/dev/sda1/`, `/dev/sda2/` and so on. Partitions on the next drive will be `dev/sdb1` etc. For NVME drives it will be `/dev/nvme0n1`, `/dev/nvme0n2` etc, and a partition can be `/dev/nvme0n1p1`.
- To actually use drives, they need to be mounted to a folder you have created, *you cannot use the device path `/dev/`*. 
- USB connected drives are automatically mounted to `/media/...`, especially USB drives. To permanently mount your drives, we will use `/mnt/` instead. 
- The system file `/etc/fstab` is a register of all your mounts, this file is used at boot to determine which partitions to mount, and where to mount them.
  - You can edit this file easily, [example here](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab). Follow it!
  - `/etc/stab` should not contain `/dev/` paths, instead the partition/filesystem UUID is used. This ID is persistent unless you remove its filesystem.
  - If you make typos or mistakes in `/etc/fstab`, you mess up your systems ability to boot. The system will boot to terminal and you can then easily edit fstab and reboot, using `sudo nano /etc/fstab`. Alternatively, you can simply restore fstab from the backup (created during step 4): `sudo mv /etc/fstabbackup /etc/fstab` and reboot again.

### How to get an overview of your drives?
- For an overview of your drives, open the Gnome Disks Utitlity (part of the App Menu top left if you used [post-install](https://github.com/zilexa/manjaro-gnome-post-install)).
- Run `sudo lsblk -f` - Shows drives, partitions and filesystems in a nice tree-view. Recommended. 
- Run `sudo fdisk -l` - lists physical drives and their partitions. Recommended especially for drives without filesystems. 
- Run `blkid` shows all UUIDs note usually you are only interested in the first UUID of each.

&nbsp;
## STEP 1. Prepare drives
### 1. Clear the drives
Before you create filesystems and folder (subvolume!) structures, you need to prepare the drives. This is different for SSDs and HDDs. 
- For SSDs: run `blkdiscard` for each drive. It is good practice to empty SSDs using blkdiscard. Discard tells the drive's firmware that the disk is empty and it improves it's performance and wear. Do this before you create any partition tables as it will erase everything of the disk. For example:
```
sudo blkdiscard /dev/sda -v
sudo blkdiscard /dev/nvme0n4 -v
```
- For HDDs: `sudo wipefs --all /dev/sda`, if the drive contains partitions (/dev/sda1, /dev/sda2 etc) you may need to do this for each partition before doing it for the whole drive.
### 2. Create Partition Tables
Highly recommended to do this via `parted` to ensure it is done correctly. See example below, ***do this for each drive.***
Run the command `parted /dev/sda`, then `mklabel gpt`, then `mkpart primary btrfs 4MiB 100%`, then `print`, then `quit`. See example below: 
```
# parted /dev/nvme0n4

GNU Parted 3.4
Using /dev/sda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) mklabel gpt
(parted) mkpart primary btrfs 4MiB 100%
(parted) print
Model: SAMSUNG EVO 860 (sata)
Disk /dev/sda`: 4.01GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name     Flags
 1      4194kB  4.01GB  4.01GB  btrfs        primary

(parted) quit
Information: You may need to update /etc/fstab.
```
Note each drive now has a partition (sda has sda1, etc): `sudo lsblk -f`

&nbsp;
## STEP 2: Create filesystems 
Make sure you have the correct device path for each drive when you use this command!
Your OS drive should be on an NVME drive (`/dev/nvmen0p1`), easy to identify and keep out of scope. 
1. Decide the purpose of each of your drives. The following purposes make sense for most users: 
    - `data0, data1, data2` for drives containing data (user data, media downloads). 
    - `backup1, backup2`: backup drives for data drives. You want at least 1 internal backup drive and 1 external (USB) drive for offline/cold backup.
    - Optional: `parity1, parity2`drive for parity, only when using SnapRAID (read the Filesystem Synopsis). 
    - Optional: `cache`: only when using MergerFS Tiered Caching. 
2. depending on the filesystem option you have chosen (see Filesystem Synopsis), create the filesystem as follows and replace LABEL for one of the purposes above.
- For [Option 1 and 2](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#option-1-all-your-data-easily-fits-on-a-single-disk): Create individual filesystems per drive: 
    ```sudo mkfs.btrfs -m dup -L data0 /dev/sda```
- [Option 3](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#option-3-use-btrfs-data-duplication): BTRFS RAID1: 
    ```sudo mkfs.btrfs -L LABEL -d raid1 /dev/sda /dev/sdb /dev/sdc /dev/sdd```

- Create filesystem for your SnapRAID drive (should be EXT4 with these options): 
    ```sudo mkfs.ext4 -L parity1  -m 0 -i 67108864 -J size=4 /dev/sda```

&nbsp;
## STEP 3: Create mountpoints for each drive
Now that each drive has a filesystem (or in case of BTRFS RAID1: is part of a filesytem), we need to create mountpoints (= paths to assign each drive or filesystem to). 
1. Open the folder `/mnt` in your file manager, right click and open it with root rights.
2. Create the mountpoints for your drives, at least 3 mountpoints: 
  - /mnt/drives/backup1, for your backupdrive
  - /mnt/pool/Users, for your ***filesystem*** used for storing users personal data (could be 1 drive or multiple using either btrfs-raid1 or MergerFS, see [Filesystem Options](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-OPTIONS.md). 
  - /mnt/pool/Media, for your ***filesystem*** used for storing downloaded media (could be 1 drive or multiple using either btrfs-raid1 or MergerFS, see [Filesystem Options](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-OPTIONS.md). 

&nbsp;
## Step 4: Configure drive mountpoints through FSTAB
This step is prone to errors. Prepare first. 

### _Preparation_
1. Make sure all drives are unmounted first: `umount /mnt/drives/data1` for all mount points, also old ones you might have in /media. You cannot mount to non-empty folder.
2. Make sure each mount point (created in Step 3) is an empty folder after unmounting.
3. Open 2 command windows:
  - In the first one, list each UUID per drive: `sudo lsblk -f`
  - In the second one, make a backup of your fstab first via `sudo cp /etc/fstab /etc/fstabbackup`
  - Stay in the second one, open fstab: `sudo nano /etc/fstab`. Whatever you do next, do not mess up the existing lines!

### _Steps to add drives_ 
1. You now want to add "DRIVE MOUNT POINTS". Use that specific section of the [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) as reference, copy only the lines you need!
2. After copying the lines make sure you fill in the right UUID, use the first command window to copy/paste the UUID.
3. Save the file via CTRL+O and exit via CTRL+X. Now test if your fstab works without errors: `sudo mount -a`. This will mount everything listed in fstab. If there is no output: Congrats!! Almost done!
4. If it says things couldn't be mounted, edit the file again, fix the errors, repeat step 3.  
5. Verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`. 

&nbsp;

TIP: ***Physically label your drives!***
If a drive stops working, you turn off your system and remove that drive. How will you know which one to remove? `data0`, `data1`, `backup1`? You would need to use the `fdisk -l` command to get the actual serial number and read the numbers of each drive. This is a big hassle. Instead, make sure you properly sticker your drives with the label/mountpoint, this way when the server is turned off, you still know which drive is what :)

***

Congratulations! Your filestems/drives are now individually accessible. 

If you haven't done so already, [learn about Linux system folderstructure, standard subvolumes and tips for your folderstructure](https://github.com/zilexa/Homeserver/blob/master/filesystem/folderstructure-recommendations.md).  \
Then continue to [Step 2b. Create Datapool(s)](https://github.com/zilexa/Homeserver/blob/master/filesystem/create-datapools.md).  \
Also notice there are tips to carefully, securily copy your data to your pool and verify your data and fix ownership and permissions: [Step 3. Data Migration](https://github.com/zilexa/Homeserver/blob/master/filesystem/data-migration.md)

***


