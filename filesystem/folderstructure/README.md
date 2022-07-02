# Folder Structure Recommendations & Data Migration

**Contents**
1. [Overview of system folders](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#1-overview-of-system-folders)
2. [Overview of mountpoints](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#2-overview-mountpoints)
3. [A folder structure for your data](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#3-a-folder-structure-of-your-data)
4. [Data Migration](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#4-data-migration)
5. [How to handle shared files between users](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#5-sharing-between-partners-and-devices)


## Folder Structure Recommendations
You might not realise the importance of a well-thought through folder structure. Consider the information below informative and use as inspiration. 

### 1. Overview of system folders:
By default, the BTRFS filesystem contains subvolumes in the root of the filesystem. The OS creates them with "@" in front of the name, to easily recognise it is a subvolume in the root of the filesystem, to be mounted to a path. The prep-server.sh script added a line to your `/etc/fstab` to manually mount the root filesystem easily: 
```
sudo mount /mnt/drives/systemdrive
```
Run this command and look at the `systemdrive` folder. You should see: 
- Created during OS setup:
  - `@` mapped to path `/` = root folder. will be snapshotted and backupped. 
  - `@cache`, mapped to path `/` = to exclude it from snapshots of the system (= snapshot of `@`)
  - `@log` mapped to path `/var/log` = to exclude it from snapshots of the system (= snapshot of `@`)
  - `@home` mapped to path`/home` = OS user account folder, will be snapshotted and backupped.
- Recommended subvolumes, created by the (post-install script)[https://github.com/zilexa/manjaro-gnome-post-install]: 
  - `@usercache` mapped to `$HOME/.cache` = to exclude it from snapshots of @home. Contains temp files only like browser cache, not browserhistory. 
  - `@downloads` mapped to `$HOME/Downloads = to exclude it from snapshots of @home.
- Subvolumes created by prep-server script: 
  - `@docker` mapped to path `$HOME/docker` = docker persistent data per container, will be snapshotted and backupped. 
- Folders created by prep-server script: 
  - `/mnt/drives/systemdrive` = the mountpoint to access the root filesystem when needed. Not mounted by default/not mounted at boot. 
  - `/mnt/drives/systemdrive/timeline` = a folder in the root filesystem to store the daily/weekly/monthly snapshots of `@`, `@home` and `@docker`. 

_Notes_
> If your whole system breaks down due to hardware failure or software corruption, you can easily replace hardware and do a clean install, then: 
>  1. run the post-install.sh and prep-server.sh scripts.
>  2. restore your `/etc/fstab` using the fstab file from the last `@` snapshot from `/mnt/drives/backup`. 
>  3. btrfs send/receive the last `@docker` snapshot from `/mnt/drives/backup1` to `/mnt/drives/systemdrive/`. See Backup Guide, step xx. 
>  4. run docker-compose. 
>  5. Schedule maintenance by adding the nightly and monthly commands to your crontab. See Maintenance Guide. 

**The docker subvolume is precious and non-expendable!** It contains: 
- a folder per container for app data/config data. 
- docker-compose.yml and .env files in the root of the folder.
- `docker/HOST` folder: containing configs and scripts for maintenance, cleanup, backup. This way, you backup a single folder, /docker == equals backup of your complete server configuration. 

### 2. Overview mountpoints: 
- `/mnt/drives` --> Just a folder with the mountpoints of your drives.
  - `/mnt/drives/{data1,data2,data3,data4}` (unless you use BTRFS RAID1 filesystem). 
  - `/mnt/drives/parity1` not automounted, will be mounted during backup run.  
  - `/mnt/drives/{backup1,backup2}` not automounted, will be mounted during backup run.  
- `/mnt/pool/Users` and `/mnt/pool/Media` --> the union of all files/folders on cache/data drives. the single access point to your data. Could be 1 drive, a MergerFS mountpoint or the mountpoint of your BTRFS RAID1 filesystem). When mounting the MergerFS pool, the folders (subvolumes behave just like folders) on the cache/datadrives will appear unionised inside `/mnt/pool/Media` and `/mnt/pool/Users`.

_Helper folders:_
- If you use MergerFS Tiered Cache: `/mnt/pool-nocache` --> the union but excluding the cache, required to offload the cache on a scheduled basis. 
- If you use MergerFS: `/mnt/pool-backup` --> If you use MergerFS, each drive will be backupped to individual folders on your `backup1` disk. To easily restore files and folders, you can simply pool/unionise those folders on your `backup1` to look just like your `/mnt/pool`. Otherwise it will be a hassle to find which file/folders are stored in which backup folder. 

### 3. A folder structure of your data
In the mountpoint of each cache/data disk: 
- Subvolume `/users` personal, non-expendable precious userdata. Protected via parity _and_ backupped to backup disk. Each user has its own folder here. 
  For example`/mnt/pool/users/Zilexa` contains the folders: \
  `/mnt/pool/users/Zilexa/Documents`  \
  `/mnt/pool/users/Zilexa/Desktop`  \
  `/mnt/pool/users/Zilexa/Pictures` etc.
- Subvolume`/media` non-personal: incoming (downloading) files, series, movies, music, books etc. Unless rare HiFi music albums, most likely no need to backup. 
  For example `/mnt/pool/Media` contains the folders:  \
  `/mnt/pool/media/Movies`  \
  `/mnt/pool/media/Series`  \
  `/mnt/pool/media/Music/Albums`  \
  `/mnt/pool/media/Incoming`  \
  `/mnt/pool/media/Incoming/complete` <-- completed downloads.  \
  `/mnt/pool/media/Incoming/incomplete` <-- ongoing downloads.   

#### HIGHLY RECOMMENDED:
The `incomplete` folder should be created as nested subvolume and should have BTRFS Copy-On-Write feature disabled for it. This will ensure 0% fragmentation:  \
- Create the subvolume: `sudo btrfs subvolume create /mnt/drives/data0/Media/incoming/incomplete` 
- Make the current user instead of root owner: `sudo chown ${USER}:${USER} /mnt/drives/data0/Media/incoming/incomplete
- Disable CoW: `chattr -R +C /mnt/drives/data0/Media/Incoming/incomplete` 
Now, completed downloads will be moved outside this subvolume to the `complete` folder, ensuring 0 fragmentation. Also, with CoW disabled for the incomplete dir, writing will be much faster. Since this is a temporary location for downloads, there is no reason to have CoW running.  \
If you use MergerFS, do the above for each drive that contains your Media/incoming folders.  \


&nbsp;

## 4. Data migration 
To migrate data to your pool `/mnt/pool/` it is best and fastest to use `btrfs send | btrfs receive` if both source and destination use btrfs filesystem. Otherwise, always securily copy data using `rsync` or it's GUI version `grsync`.
> Use MergerFS cache? Copy files to the nocache pool, `/mnt/pool-nocache` otherwise you end up filling your cache! You will still see all data in `/mnt/pool`.


### From any drive or folder, regardless of filesystem 
- _Moving files and folders from one drive to the other_
  You want to make sure files are correctly read and written, without read or write errors. For that, we have rsync. If you are copying lots of data while doing other activities, make sure to append `nocache`: 
```
nocache rsync -axHAXE --info=progress2 --inplace --no-whole-file --numeric-ids  /media/my/usb/drive/ /mnt/pool-nocache
```
- _Moving files and folders to another folder on the same drive_ 
The `mv` command is used to move or rename folders. But it doesn't include hidden files. This way it does:
```
sudo find /source/folder -mindepth 1 -prune -exec mv '{}' /destination/folder \;   
```

### From BTRFS to BTRFS subvolume
While rsync needs to generate checksums, BTRFS filesystem already has full metadata available, hence copying a subvolume using `btrfs send|btrfs receive` is much faster than rsync while just as secure. 
1. You must create a read-only snapshot of your subvolume first, using `-r` option: 
  ```
  sudo btrfs subvolume snapshot -r /source/folder/subvolumename /source/otherfolder/readonlysnapshot
  ```
2. Then send it to the destination:
  ```
  sudo btrfs send /source/otherfolder/readonlysnapshot | sudo btrfs receive /destination/folder/
  ```
3. And finally create a read-write snapshot, to make it usable, this will be the final destination:  \
  ```
  sudo btrfs subvolume snapshot /destination/folder/readonlysnapshot /destination/folder/subvolumename
  ```
Then you can then delete the read-only snapshot using `sudo btrfs subvolume delete /destination/folder/readonlysnapshot`. 

### Verify your copied data!
Highly recommended for precious data to double-check all data is really identical to the source. 
- Fast method:
  ```
  diff -qrs /source/otherfolder/snapshot/ /destination/folder/snapshot/
  ```
 - Checksum based (slower):
   ```
   rsync --dry-run -crv --delete /source/otherfolder/snapshot/ /destination/folder/snapshot/
   ``` 
 <sub>nothing will be deleted or modified. See info: [rsync manpage](https://linux.die.net/man/1/rsync)</sub>
 
&nbsp;

## 5. Sharing between partners and devices
#### 5.1 Sharing data locally
[How-To NFSv4.2](https://github.com/zilexa/Homeserver/tree/master/filesystem/networkshares_HowTo-NFSv4.2) is the fastest network protocol, allows server-side copy just like more common smb/samba and works on all OS's, although only for free on Mac and Linux. 
I only use this to share folders that are too large to actually sync with my laptop. For example photo albums. To sync files to laptops/PCs, Syncthing is the recommended application (installed via docker). 


#### 5.2 Sharing files between partners/family with a structure that supports online access for all
The issue: My partner and I share photo albums, administrative documents etc. How to ensure these files are not owned by just 1 of us? Because if 1 of us owns it, the other will not have direct online access. This is the same limitation you have when using Dropbox/Google/OneDrive, only 1 of you owns the files and has to share them with the other. This complicates the organisation of your shared data. 

Just like that, on the local filesystem, whether shared in your home network, synced to your laptops, you will each be forced to look into each others folders to find the shared stuff. 

To ensure the local filesystem AND the online filecloud always allows direct access to the stuff you share with your partner, the easiest solution is to create a `third user` that owns a userfolder called `shared`. On the local server filesystem, those shared files can simply be made accessible in _$HOME/Documents, Pictures, Desktop_ while actually being stored in `mnt/pool/users/Shared`. Your own data of each of you can be made accessible via `$HOME/yourname` and `$HOME/partnername`. Simple, clean and neat organisation of your data! 

#### Solution
To keep the filesystem structure simple, we create a 3rd user called `Shared`. OPTION 1: 
If you used my [post-install](https://github.com/zilexa/manjaro-gnome-post-install) script, the folders _Desktop, Documents, Pictures, Media_ are already in a seperate subvolume in `/mnt/users/systemusername`. 
- This could simply become the folder of your `Shared` user, just migrate that folder to your `/mnt/pool/users/`. 
- Then update the symlinks to `$HOME` using `ln -nfs /mnt/pool/users/Shared/Desktop $HOME/Desktop` and do that for _Documents, Pictures_ as well.  

OPTION 2: 
- If you did not use my post-install simply create a folder in your pool `mnt/pool/users/Shared` and create _Desktop, Documents, Pictures_ in there.
- Then symlink each of them to your $HOME like this: `ln -s mnt/pool/users/Shared/Documents $HOME/Documents`. 
  - Before you do this, you must delete the folders in $HOME first (migrating any folder contents to the respective folder in `/mnt/pool/users/Shared`). 
  - You cannot delete the `$HOME/Desktop` folder easily. Rename it first (`$HOME/Desktoptemp`), then create the symlink. Then edit the file `$HOME/.config/user-dirs.dirs` changing the path of _Desktop_ back to `$HOME/Desktop`. Then delete `Desktoptemp`. 


## How to use the setup-folderstructure script
The script prep-folderstructure.sh will create the folder structure as described AND map those `Shared` documents and media folders to the server /home dir, replacing those personal folders for symlinks. Adjust at will before running it.
1. Get the script: 
`cd Downloads`
`wget https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/create_folderstructure.sh`
2. Before you run it, open it open the script in a text editor
   - Use the top commands and fix the permissions, change `asterix` to your user account.
   - Also make changes/remove parts you do not want.
3. Run the script via `bash create_folderstructure.sh`. Do not use sudo. if you get permission denied errrors, you have to fix those first. 
