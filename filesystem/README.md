# Guide: A Modern Homeserver _filesystem_ 

# SYNOPSIS: [Filesystem explained](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md)
_Read the Synopsis before continuing with this guide, to understand what you are about to do._

## Requirements: 
1. The OS disk should be BtrFS, this should be chosen during [OS Installation](https://github.com/zilexa/manjaro-gnome-post-install). 
2. You have ran the prep-docker.sh script and the server tools have been installed. 
3. You have read the synopsis, had a good night rest and are ready to decide which of the 3 options is best for you!

&nbsp;


## General need-to-knows
- In Linux, every piece of hardware has its own path starting with `/dev/...` For example, SATA drives are listed as `/dev/sda/` the next drive `/dev/sdb/` and so on. Partitions will be `/dev/sda1/`, `/dev/sda2/` and so on. Partitions on the next drive will be `dev/sdb1` etc. 
- No partitions are needed, when you have finished this part of the guide, there should not be a `sda1`. That just overcomplicate things. BTRFS uses subvolumes instead.
- To actually use drives, they need to be mounted to a folder you have created, you cannot use the device path `/dev/`. 
- The system file `/etc/fstab` is a register of all your mounts. You can edit this file easily, [example here](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab). Follow it!
- `/etc/stab` should not contain `/dev/` paths, instead the disk ID is used. This ID is persistent unless you remove its filesystem.
- The system usually mounts drives by default inside `/media/`, especially USB drives. To permanently mount your drives, we will use `/mnt/` instead. 
- If the drive name, the path to mount to etc are incorrect in /etc/fstab, you will boot into command line and will need to fix it (or comment out) using `sudo nano /etc/fstab`. Alternatively, you can simply restore since this guide requires you to make a backup. Restoring: `sudo mv /etc/fstabbackup /etc/fstab` and reboot again. 

## How to properly list your drives
Visual: App menu > Disks. Alternatively the following commands can be used.  \
- `sudo fdisk -l` - lists physical drives and their partitions. Recommended especially for drives without filesystems. 
- `sudo lsblk -f` - Shows drives, partitions and filesystems in a nice tree-view. Recommended. 
- `blkid` shows all UUIDs note usually you are only interested in the first UUID of each.

&nbsp;
## Step 1: Erase existing filesystems, partitions, create GPT new partition table
To start clean, remove all filesystems and partition tables. You will have an empty disk without filesystems, partitions, partition table.
```
sudo wipefs --all /dev/sda
```

## Step 2: Create filesystems 
Make sure you have the correct device path for each drive when you use this command. 
Your OS drive should be on an NVME drive (`/dev/nvmen0p1`), easy to identify and keep out of scope. If you followed the hardware recommendation, you only use SATA drives (HDD or SSD) that means the paths will always be like `/dev/sdX`. 
1. Decide the purpose of each of your drives. The following purposes make sense for most users: 
    - `data0, data1, data2` etc: drive containing your user and media data. 
    - `backup1, backup2` etc: drive containing backups. 
    - `parity1, parity2` etc: drive for parity, only when using SnapRAID (read the Filesystem Synopsis). 
    - `cache`: only when using MergerFS Tiered Caching. 
2. depending on the filesystem option you have chosen (see Filesystem Synopsis), create the filesystem as follows and replace LABEL for one of the purposes above.
- For (Option 1 and 2)[https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#option-1-all-your-data-easily-fits-on-a-single-disk]: Create individual filesystems per drive: 
    ```mkfs.btrfs -m dup -L data0 /dev/sda```
- (Option 3)[https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#option-3-use-btrfs-data-duplication]: BTRFS RAID1: 
    ```mkfs.btrfs -L LABEL -d raid1 /dev/sda /dev/sdb /dev/sdc /dev/sdd```

- Create filesystem for your SnapRAID drive (should be EXT4 with these options): 
    ```sudo mkfs.ext4 -L parity1  -m 0 -i 67108864 -J size=4 /dev/sda```

&nbsp;
## Step 3: Create mountpoints for each drive
Now that each drive has a filesystem (or in case of BTRFS RAID1: is part of a filesytem), we need to create mountpoints (= paths to assign each drive or filesystem to). 
1. Open the folder /mnt in your file manager, right click and open it with root rights.This will give you a nice view of the structure.
2. Go back to Terminal: with the following command, you create multiple folders.   
```
sudo mkdir -p /mnt/disks/{cache,data0,data1,data2,data3,parity1,backup1,backup2}
```
&nbsp;
## Step 4: Configure drive mountpoints through FSTAB
This step is prone to errors. Prepare first. 

### _Preparation_
1. Make sure all disks are unmounted first: `umount /mnt/disks/data1` for all mount points, also old ones you might have in /media. You cannot mount to non-empty folder.
2. Make sure each mount point (created in Step 3) is an empty folder after unmounting.
3. Open 2 command windows:
  - In the first one, list each UUID per disk: `sudo lsblk -f`
  - In the second one, make a backup of your fstab first via `sudo cp /etc/fstab /etc/fstabbackup`
  - Stay in the second one, open fstab: `sudo nano /etc/fstab`. Whatever you do next, do not mess up the existing lines!

### _Steps to add drives_ 
1. You now want to add "DRIVE MOUNT POINTS". Use that specific section of the [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) as reference, copy only the lines you need!
2. After copying the lines make sure you fill in the right UUID, use the first command window to copy/paste the UUID.
3. Save the file via CTRL+O and exit via CTRL+X. Now test if your fstab works without errors: `sudo mount -a`. This will mount everything listed in fstab. If there is no output: Congrats!! Almost done!
4. If it says things couldn't be mounted, edit the file again, fix the errors, repeat step 3.  
5. Verify your disks are mounted at the right paths via `sudo lsblk` or `sudo mount -l`. 

Congratulations! Your filestems/drives are now individually accessible. In the next steps you decide the folder structure, create subvolumes that will actually hold the data and can easily be snapshotted/backupped and mount those subvolumes in fstab. 

TIP: ***Physically label your drives!***
If a drive stops working, you turn off your system and remove that drive. How will you know which one to remove? `data0`, `data1`, `backup1`? You would need to use the `fdisk -l` command to get the actual serial number and read the numbers of each drive. This is a big hassle. Instead, make sure you properly sticker your drives with the label/mountpoint, this way when the server is turned off, you still know which drive is what :)



