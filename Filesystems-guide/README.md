# Step 2: Filesystems & Folderstructure

# Recommended read: [Filesystem Options](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md)
_3 options for filesystems are explained, choose which one is best for you before continuing with step 2.2 below._

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
  - You can edit this file easily, [example here](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/fstab-example). Follow it!
  - `/etc/stab` should not contain `/dev/` paths, instead the partition/filesystem UUID is used. This ID is persistent unless you remove its filesystem.
  - If you make typos or mistakes in `/etc/fstab`, you mess up your systems ability to boot. The system will boot to terminal and you can then easily edit fstab and reboot, using `sudo nano /etc/fstab`. Alternatively, you can simply restore fstab from the backup (created during step 4): `sudo mv /etc/fstabbackup /etc/fstab` and reboot again.

### How to get an overview of your drives?
- For an overview of your drives, open the Gnome Disks Utility (part of the App Menu top left if you used [post-install](https://github.com/zilexa/manjaro-gnome-post-install)).
- Run `sudo lsblk -f` - Shows drives, partitions and filesystems in a nice tree-view. Recommended. 
- Run `sudo fdisk -l` - lists physical drives and their partitions. Recommended especially for drives without filesystems. 
- Run `blkid` shows all UUIDs note usually you are only interested in the first UUID of each.

&nbsp;
## STEP 2.1. Prepare drives
### 1. Clear the drives
Before you create filesystems and folder (subvolume!) structures, you need to prepare the drives. This is different for SSDs and HDDs. 
- For SSDs: run `blkdiscard` for each drive. It is good practice to empty SSDs using blkdiscard. Discard tells the drive's firmware that the disk is empty and it improves it's performance and wear. Do this before you create any partition tables as it will erase everything of the disk. For example:
```
sudo blkdiscard /dev/sda -v
or
sudo blkdiscard /dev/nvme0n2 -v
```
- For HDDs: `sudo wipefs --all /dev/sda`, if the drive contains partitions (/dev/sda1, /dev/sda2 etc) you may need to do this for each partition before doing it for the whole drive.

*Note from now on, all example commands are shown with SATA device paths. You can simply change it to your situation, whether NVME or SATA*
### 2. Create Partition Tables
It is highly recommended to do this via `parted`, instead of a graphical utility, to ensure it is done correctly.  \
Run the command `sudo parted /dev/sda`, then `mklabel gpt`, then `mkpart primary btrfs 4MiB 100%`, then `print`, then `quit`.  \
See example below, ***do this for each drive.***
```
# parted /dev/sda

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
Note each drive now has a partition (sda has sda1, etc): `sudo lsblk -f` and see the Disk Utility. 

&nbsp;
## STEP 2.2: Create filesystems 
Make sure you have the correct device path for each drive when you use this command!
Your OS drive should be on an NVME drive (`/dev/nvmen0p1`), easy to identify and keep out of scope. 
1. Decide the purpose of each of your drives! Highly recommended to have separate drives for *Media* and for *Users*.  \
Easiest would be a single drive for each [(Filesystem Option 1)](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md#option-1-all-your-data-easily-fits-on-a-single-disk) Alternatively a single filesystem for each where the filesystems span across multiple drives [(Filesystem Option 3)](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md#option-3-use-btrfs-data-duplication) or multiple drives, each their own filesystem, pooled together with MergerFS mountpoints: one MergerFS mountpoint for *Media* and one for *Users* [(Filesystem Option 2)](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md#option-2-individual-filesystems-drives-pooled-via-mergerfs). 
2. The following drive labels make sense:
  - `users` for the filesystem containing users personal data.
  - `media` for the filesystem containing media downloads.
  - `cache, data0, data1, data2` etc. when you are going to pool multiple *numbered* drives via MergerFS, 1 pool for Users and 1 pool for Media.
  - `backup1, backup2`: backup drives for the above. 
  - Optional: `parity1, parity2`drive for parity, only when using SnapRAID (read the Filesystem Synopsis). 
  - Optional: `cache`: only when using MergerFS Tiered Caching. 
3. Create the filesystems for each drive: 
- For a single filesystem per drive (backup drives and [Option 1: single drive BTRFS filesystem](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md#option-1-all-your-data-easily-fits-on-a-single-disk)): Create individual filesystems per drive using the correct label per device (you choose):  \
    ```sudo mkfs.btrfs -m dup -L users /dev/sda1```  \
    ```sudo mkfs.btrfs -m dup -L media /dev/sdb1```  \
    ```sudo mkfs.btrfs -m dup -L backup1 /dev/sdc1```  

- For a filesystem spanning multiple drives [(Option 3: multiple drives BTRFS filesystem (btrfs-raid1))](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md#option-3-use-btrfs-data-duplication) for Users and a filesystem spanning multiple drives for Media, each with 2 drives:  \
    ```sudo mkfs.btrfs -L users -d raid1 /dev/sda1 /dev/sdb1```  \
    ```sudo mkfs.btrfs -L media -d raid1 /dev/sdc1 /dev/sdd1```  
    
- for [Option 2: MergerFS](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md#option-1-all-your-data-easily-fits-on-a-single-disk) simply create the single filesystem per drive, but use labels like "data0", "data1", "data2" etc instead of "users" or "media", because the drives will be pooled via MergerFS.  

Optional: create filesystem for your SnapRAID drive (should be EXT4 with these options):     ```sudo mkfs.ext4 -L parity1  -m 0 -i 67108864 -J size=4 /dev/sda```

&nbsp;
## STEP 2.3: Create mountpoints for each drive
Now that each drive has a filesystem (or in case of BTRFS RAID1: is part of a filesytem), we need to create mountpoints (= paths to assign each drive or filesystem to). 
1. Open the folder `/mnt` in your file manager, right click and *open with root*.
2. Create the mountpoints for your drives, at least 3 mountpoints: 
  - 1 for each backup drive: `/mnt/drives/backup1`
  - 1 for the Users datapool: `/mnt/pool/Users` for your ***filesystem*** used for storing users personal data (could be 1 drive or multiple using either btrfs-raid1 or MergerFS, see [Filesystem Options](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md). 
  - 1 for the Media datapool: `/mnt/pool/Media`, for your ***filesystem*** used for storing downloaded media (could be 1 drive or multiple using either btrfs-raid1 or MergerFS, see [Filesystem Options](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/Filesystems-options.md). 
  - Only if you use MergerFS: 
    - `mnt/drives/data0`, `/mnt/drives/data1`, `/mnt/drives/data2` etc.
      - Only if you will use MergerFS with a cache drive: `/mnt/drives/cache` and `/mnt/pool-nocache` this way you can easily offload the cache (`/mnt/drives/cache`) to this mountpoint, which will be a MergerFS mount without the cache drive.  

&nbsp;
## Step 2.4: Configure drive mountpoints through FSTAB
This step is prone to errors. Prepare first. 

### _Preparation_
1. Make sure all drives you are going to modify in fstab, are unmounted first: `umount /mnt/drives/data1` for example.
2. Make sure each mount point (created in Step 3) is an *empty folder* after unmounting. No apps or services using these paths should be running!
3. Create a backup of fstab: `sudo cp /etc/fstab /etc/fstabbackup`
4. Run `sudo lsblk -f` for an overview, also have Disk Utility open next to it. 
5. Now open your fstab in the nice graphical texteditor Pluma, with elevated rights to be able to edit: `sudo dbus-launch pluma /etc/fstab`
6. Open [the example fstab](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/fstab-example), *note all UUIDs are missing in this example. Use the partition UUIDs you see in terminal/disk utility*. 

### _Steps to add drives_ 
1. Go through the example, add the lines you are missing under "AUTO-MOUNTED AT BOOT". 
    - Note if you used [Post-Install](https://github.com/zilexa/manjaro-gnome-post-install) it has created subvolumes, mountpoints for `Downloads` and `.cache` because they should always be excluded from backup snapshots created by the OS. 
    - Note prep-server.sh has created a not-automatically-mounted line to mount the entire system drive. Required for backups and when you want to create/modify subvolumes on the systemdrive.
3. Make sure you add the lines under "NOT AUTOMATICALLY MOUNTED" for the system drive and the backup drives you might have.
4. If you use BTRFS-RAID1, you simply use the UUID of the first drive in that pool. So you only need 1 line here, for each BTRFS-RAID pool. 
    - *Ensure you did not make any mistakes. Double check!*
5. Make your file look nice and readible, like the example, use as much comments/descriptions as you need! 
6. Save the file. Run `sudo systemctl daemon-reload` to load the changes. Run `sudo mount -a` to mount all auto-mounted filesystems. 
7. If there are errors, unmount the drives before editing the file again. If not, verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`.
8. Do a reboot just to test all is working fine. If you do not boot to the user interface, simply edit fstab (`sudo nano /etc/fstab`) and add a "#" to comment out the drives that gave an error, or fix the typo that you see. 


***
TIP: ***Physically label your drives!***
If a drive stops working, you turn off your system and remove that drive. How will you know which one to remove? `users`, `media`, `backup1`? You would need to use the `fdisk -l` command to get the actual serial number and read the numbers of each drive. This is a big hassle. Instead, make sure you properly sticker your drives with the label/mountpoint, this way when the server is turned off, you still know which drive is what :)
***
&nbsp;

## Step 2.5 Create subvolumes
Optionally read [Folderstructure Recommendations](https://github.com/zilexa/Homeserver/blob/master/Filesystems-guide/folderstructure-recommendations.md).  \
**Users**: Each user should have its own subvolume. Consider this subvolume to be each users virtual drive. Users will be individually snapshotted and backupped, allowing you to easily restore individual users storage when needed. You could even simply mount their snapshot into this folder to give them access to their timeline backups. 
**Media**: Create a subvolume for Shows, Movies, Music and incoming. This gives you flexibility in the future when you need to move these folders to other drives. Remember, btrfs send/receive is the fastest way to copy/move folders, since it will happen on a filesystem-level, with a metadata (checksum) aware filesystem. Alternatives like rsync need to calculate checksums for each file, slowing down the process greatly. 

### _Steps to create a subvolume_
This can only be done through the terminal. For example: 
```
sudo btrfs create subvolume /mnt/pool/users/User1
```
Do this for all mentioned folders. You should end up with the following: 
- `/mnt/pool/users/User1`
- `/mnt/pool/users/User2`
- etc..
For Media, to ensure the best practice/recommended setup for apps/services that automatically manage the downloads of your shows like Sonarr and other *arr apps, use the following folder structure, these should all be created using the command above: 
- `/mnt/pool/media/Movies`
- `/mnt/pool/users/Shows`
- `/mnt/pool/users/Books`
- `/mnt/pool/users/Music`
- `/mnt/pool/users/incoming` --> Also create a folder (not subvolume) `complete` inside this folder. 
- `/mnt/pool/users/incoming/incomplete` --> yes, this should be a subvolume within a subvolume (nested). This is your temporary download folder. Files will be moved to their permanent location when finished downloading. By using a nested subvol for downloads, you ensure 0 fragmentation, since files will be moved as a whole to their permanent location (Movies, Shows, Music, Books or incoming/complete for manual downloads). 

## Step 2.5 set ownership and permissions
Subvolumes were probably created with sudo. Because the root folders /mnt/pool is owned by root (which is fine, you want to limit the ability for someone with inherited regular user rights to delete folders). But to be able to use the subvolumes you just created, you should set ownership and permissions. 

Set ownership (always use the username you logged in with): 
```
sudo chown -R username:username /mnt/pool/users
sudo chown -R username:username /mnt/pool/media
```
Set permissions: 
```
sudo chmod -R 775 /mnt/pool/users
sudo chmod -R 775 /mnt/pool/media
```

&nbsp;

## Step 2.6 (optional): Create symlinks to your home folder
Linux supports symlinks, similar to shortcuts, with the difference that a symlink acts just like a _real_ folder, but in reality links to the already existing folder. You could symlink `mnt/pool/media` to $HOME to have quick access. Note the existing folders need to be renamed or deleted since you cannot have 2 folders with the same name. 
```
ln -s /mnt/pool/media $HOME/Media
```
You can do the same with your Documents, Pictures, Desktop: 
```
ln -s /mnt/pool/users/User1/Documentsss $HOME/Documents
```
To update an existing symlink, simply delete the symlink via filemanager or terminal and then create a new one. A faster option is this command: 
```
ln -fns /mnt/pool/users/User1/Documents $HOME/Documents
```
Notes: 
- If you want to replace the default `Desktop` folder, you must rename that folder first, create the symlink, then edit the file `/home/asterix/.config/user-dirs.dirs` This file is required for the Operating System. Make sure the paths in this file are correct. It also contains a path for "Public", I would recommend to change its path to $HOME/Downloads. 
- Notice the folder `$HOME/Templates` you might want to move it to Documents. Don't delete it, it contains the actions of "Create new Document" in your context menu.
- ` $HOME/Downloads` should be considered a temporary folder, no need to have it in your pool. Make sure this folder is a subvolume.
***

Congratulations! Your filestems/drives are now individually accessible and you have a basic folderstructure. time to use your data storage pools! Go to [Step 3. Data Migration](https://github.com/zilexa/Homeserver/blob/master/filesystem/data-migration.md) to learn how to properly copy your data, verify copies are bit-for-bit perfect and fix ownership and permissions.

***

&nbsp;


