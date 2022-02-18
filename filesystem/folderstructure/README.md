# STEP 2: Folder Structure Recommendations & Data Migration

**Contents**
1. [Data Migration](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#1-data-migration)
2. [Sharing between partners and devices](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#3-extras)
3. [How to use the setup-folderstructure script](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#how-to-use-the-setup-folderstructure-script)

## Folder Structure Recommendations
You might not realise the importance of a well-thought through folder structure. Consider the information below informative and use as inspiration. 

#### 1. Overview of system subvolumes and folders:
When a BTRFS snapshot is made of a subvolume, its nested subvolumes are excluded. This way, we can exclude folders that should not be backupped or should be backupped separately, with a different cadence or a different retention policy.  

On the OS system SSD the following subvolumes will be created: 
- By OS: root subvolume `@` mapped to path `/` = root folder. will be snapshotted and backupped. 
- By OS: root subvolume `@home` mapped to path`/home` --> user folder, will be snapshotted and backupped.
- By prep-server script: root subvolume `@docker` mapped to path `$HOME/docker` --> docker persistent data per container, will be snapshotted and backupped. 
- By OS: `@cache`, `@log`mapped inside path `/var/` --> just to ensure these temporary folders are excluded in snapshots.
- By prep-server script: `@system-snapshots` --> To store snapshots of `@`, `@home` and `@docker`. 
- By prep-server script: `/mnt/btrfs-root` --> to mount the btrfs root, required to create `@docker` and to backup the snapshots of `@`, `@home`, `@docker`. Not auto-mounted.

_Notes_
If your whole system breaks down due to hardware failure or software corruption, you can easily replace hardware and do a clean install, run the 2 scripts again and only recover the `@docker` from your `/mnt/disks/backup1` or `/mnt/disks/backup1` or external backup disk. You will be up and running in minutes, without having to configure your apps. All maintenance scripts are in that same docker subvolume, you only need to re-enable scheduling. 

**The docker subvolume is precious and non-expendable!** It contains: 
- a folder per container for app data/config data. 
- docker-compose.yml and .env files in the root of the folder.
- `docker/HOST` folder: containing configs and scripts for maintenance, cleanup, backup. This way, you backup a single folder, /docker == equals backup of your complete server configuration. 

#### 2. Overview of drive mounts: 
- `/mnt/disks` --> Just a folder with the mountpoints of your drives.
  - `/mnt/disks/{data1,data2,data3,data4}` (unless you use BTRFS RAID1 filesystem). 
  - `/mnt/disks/parity1` not automounted, will be mounted during backup run.  
  - `/mnt/disks/{backup1,backup2}` not automounted, will be mounted during backup run.  
- `/mnt/pool` --> the union of all files/folders on cache/data disks. the single access point to your data. Could be 1 drive, a MergerFS mountpoint or the mountpoint of your BTRFS RAID1 filesystem). 

_Helper folders:_
- If you use MergerFS Tiered Cache: `/mnt/pool-nocache` --> the union but excluding the cache, required to offload the cache on a scheduled basis. 
- If you use MergerFS: `/mnt/pool-backup` --> If you use MergerFS, each drive will be backupped to individual folders on your `backup1` disk. To easily restore files and folders, you can simply pool/unionise those folders on your `backup1` to look just like your `/mnt/pool`. Otherwise it will be a hassle to find which file/folders are stored in which backup folder. 

#### 3. Data folder structure
In the mountpoint of each cache/data disk: 
- Subvolume `/Users` personal, non-expendable precious userdata. Protected via parity _and_ backupped to backup disk. 
- Subvolume`/Media` non-personal: incoming (downloading) files, series, movies, music, books etc. Unless rare HiFi music albums, most likely no need to backup.  
- `/.snapraid` contains the snapraid content file.
- Nested subvolume `/data/Media/TV/incoming/incomplete`with `chattr -R +C incomplete` applied to it from its parent folder.\Reason: Downloaded files can be heavily fragmented. The torrent client can be set to download to `incomplete` and move files to `complete` when finished. By having a subvol for incomplete, files will be newly created (instead of just updating the index table) in complete. Zero fragmentation!

**When mounting the MergerFS pool, the folders (subvolumes behave just like folders) on the cache/datadisks will appear unionised inside `/mnt/pool`:**\
`mnt/pool/Users`, `mnt/pool/TV` and `/mnt/pool/Music`.  

&nbsp;

## 4. Data migration 
#### 4.1 Moving files to your server
- To copy files from existing disks, connect them via USB. 
- Copy files to the nocache pool, `/mnt/pool-nocache` otherwise you end up filling your SSD! You will still see all data in `/mnt/pool`
- While copying via the file manager is an option I highly recommend using rsync as it will verify each disk read and write action, to ensure the files are copied correctly. Also it includes options to have 100% identical copy with all of your files metadata and attributes. 

From non-btrfs disk to btrfs disk (For a GUI, install the Grsync app: `sudo apt install grsync`):\
`nocache rsync -axHAXE --info=progress2 --inplace --no-whole-file --numeric-ids  /media/my/usb/drive/ /mnt/pool-nocache`

Between btrfs disks, if your data is in a subvolume, create a read-only snapshot first:\
`sudo btrfs subvolume snapshot -r /media/myname/usbdrive/mysubvol /media/myname/usbdrive/mysnapshot`\
Then send it to the destination:\
`sudo btrfs send /media/myname/usbdrive/mysnapshot | sudo btrfs receive /mnt/disks/data1`\
Optional: verify the data is identical by doing a dryrun with rsync to list files that are missing/not 100% identical (checksum based):\
`rsync -rvnc --delete /media/myname/usbdrive/mysnapshot/ /mnt/disks/data1/mysnapshot`, nothing will be modified. More info: [rsync manpage](https://linux.die.net/man/1/rsync). 

#### 4.2 Move files within your filesystem
To move files within a subvolume, copy them first, note this action will be instant on btrfs! Files won't be physically moved:\
`cp --reflink=always /my/source /my/destination`

Then when you are satisfied, delete the source folder/files. Alternatively, you can use the rename/move command `mv /my/source /my/destination` to rename or move files/folders. It will also be instant. Note you can use mv also on subvolumes to rename them. 


## 5. Sharing between partners and devices
#### 5.1 Sharing data locally
NFSv4.2 is the fastest network protocol, allows server-side copy just like more common smb/samba and works on all OS's, although only for free on Mac and Linux. 
I only use this to share folders that are too large to actually sync with my laptop. For example photo albums. To sync files to laptops/PCs, Syncthing is the recommended application (installed via docker). 

&nbsp;

#### 5.2 Sharing files between partners/family with a structure that supports online access for all
The issue: My partner and I share photo albums, administrative documents etc. With Google Drive/DropBox/Onedrive, 1 user would own those files and share them with the other, but this only works in the online environment. The files are still stored in your folder. 
But your partner won't see those files on the local filesystem of your laptop, PC, workstation or server: only if she uses the web application (FileRun or NextCloud). As you will prefer to use the local files directly, this can be frustrating and annoying as she has to go find your folder with those files.

#### Solution
1. To keep the filesystem structure simple, we create a 3rd user called `Shared`. 
2. `/mnt/pool/Users/Shared/{Documents, Desktop, Photos}` contains our shared photo albums, shared documents etc and symlinks to these folders replace the common personal folders in $HOME. 
3. in $HOME, the common personal folders are replaced with symlinks to `Users/Myusername` and `Users/Herusername`. 
4. Each one of our user folders (`/mnt/pool/Users/Myname` and `mnt/pool/Users/Hername` are also symlinked into `$HOME` and visible next to the symlinked Documents, Photos etc.
7. Extra benefit: on a shared home laptop, via Syncthing you can have a copy of yours and her Users/ folders via (Syncthing manages a realtime 2-way sync of folders) and you can sync the Documents, Desktop etc folder as well. 
  - This way, whether you work on your server or laptop, you will have the same files. And you can work offline on those files (syncthing will sync when there is a connection). 
  - You can have the same desktop/documents etc folders on multiple systems. 
  - You can mount folders that are too large for the laptop like Photosvia NFS, allowing the exact same folder structure (and files) in $HOME on your laptop as on your server! 

## How to use the setup-folderstructure script
The script prep-folderstructure.sh will create the folder structure as described AND map those `shareduser` documents and media folders to the server /home dir, replacing those personal folders for symlinks. Adjust at will before running it.
1. Get the script: 
`cd Downloads`
`wget https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/create_folderstructure.sh`
2. Before you run it, open it open the script in a text editor
   - Use the top commands and fix the permissions, change `asterix` to your user account.
   - Also make changes/remove parts you do not want.
3. Run the script via `bash create_folderstructure.sh`. Do not use sudo. if you get permission denied errrors, you have to fix those first. 
