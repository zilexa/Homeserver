# Folder Structure Recommendations & Data Migration

**Contents**
1. [Overview of system folders](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#1-overview-of-system-folders)
2. [Overview of mountpoints](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#2-overview-mountpoints)
3. [A folder structure for your data](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#3-a-folder-structure-of-your-data)
4. [How to handle shared files between users](https://github.com/zilexa/Homeserver/tree/master/filesystem/folderstructure#5-sharing-between-partners-and-devices)


## Folder Structure Recommendations
You might not realise the importance of a well-thought through folder structure. Consider the information below informative and use as inspiration. 

### 1. Overview of system folders:
By default, the BTRFS filesystem contains subvolumes in the root of the filesystem. The OS creates them with "@" in front of the name, to easily recognise it is a subvolume in the root of the filesystem, to be mounted to a folder. The prep-server.sh script added a line to your `/etc/fstab` to manually mount the root filesystem easily: 
```
sudo mount /mnt/drives/system
```
Run this command and look at the `system` folder. You should see: 
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
  - `/mnt/drives/system` = the mountpoint to access the root filesystem when needed. Not mounted by default/not mounted at boot. 
  - `/mnt/drives/system/snapshots` = a folder in the root filesystem to store the daily/weekly/monthly snapshots of `@`, `@home` and `@docker`. 

_Notes_
> If your whole system breaks down due to hardware failure or software corruption, you can easily replace hardware and do a clean install, then: 
>  1. run the post-install.sh and prep-server.sh scripts.
>  2. restore your `/etc/fstab` using the fstab file from the last `@` snapshot from `/mnt/drives/backup`. 
>  3. btrfs send/receive the last `@docker` snapshot from `/mnt/drives/backup1` to `/mnt/drives/system/`. See Backup Guide, step xx. 
>  4. run docker-compose. 
>  5. Schedule maintenance by adding the nightly and monthly commands to your crontab. See Maintenance Guide. 

**The docker subvolume is precious and non-expendable!** It contains: 
- a folder per container for app data/config data. 
- docker-compose.yml and .env files in the root of the folder.
- `docker/HOST` folder: containing configs and scripts for maintenance, cleanup, backup. This way, you backup a single folder, /docker == equals backup of your complete server configuration. 

### 2. Overview server storage mountpoints: 
- `/media/yourusername/drivename` --> automatically mounted USB drives. 
- `/mnt/drives{system, backup1, parity1}` --> a folder created by prep-server.sh or you, when needed (on-demand), root filesystems like `system`, `backup1` can be mounted here.
- `/mnt/pool/users` and `/mnt/pool/media` --> filesystem for users and filesystem for media mounted here automatically. A filesystem could be a single drive or multiple drives via BTRFS-RAID1 or MergerFS. When using MergerFS, the individual drives need to be mounted already, you can use `mnt/drives/data1` etc for that. 

_Helper folders:_
- If you use MergerFS Tiered Cache: `/mnt/pool-nocache` --> the union but excluding the cache, required to offload the cache on a scheduled basis. 
- If you use MergerFS: `/mnt/pool-backup` --> If you use MergerFS, each drive will be backupped to individual folders on your `backup1` disk. To easily restore files and folders, you can simply pool/unionise those folders on your `backup1` to look just like your `/mnt/pool`. Otherwise it will be a hassle to find which file/folders are stored in which backup folder. 

### 3. A folder structure of your data
In the mountpoint of each cache/data disk: 
- Mountpoint `/mnt/pool/users` contails personal, non-expendable precious userdata. Each user has its own *subvolume* here. By having each user in its own subvolume, you can easily create snapshots and backup each user. You can mount older versions (snapshots) to the user folder to give a user access to their backup history.  
  For example, `sudo btrfs subvolume create /mnt/pool/users/User1` and then create the following folders: \
  `/mnt/pool/users/User1/Documents`  \
  `/mnt/pool/users/User1/Desktop`  \
  `/mnt/pool/users/User1/Pictures`
  `/mnt/pool/users/User1/Phone-sync
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

## 4. Sharing between partners and devices
#### 4.1 Sharing data locally
[How-To NFSv4.2](https://github.com/zilexa/Homeserver/tree/master/filesystem/networkshares_HowTo-NFSv4.2) is the fastest network protocol, allows server-side copy just like more common smb/samba and works on all OS's, although only for free on Mac and Linux. 
I only use this to share folders that are too large to actually sync with my laptop. For example photo albums. To sync files to laptops/PCs, Syncthing is the recommended application (installed via docker). 


#### 4.2 Sharing files between partners/family with a structure that supports online access for all
The issue: My partner and I share photo albums, administrative documents etc. How to ensure these files are not owned by just 1 of us? Because if 1 of us owns it, the other will not have direct online access. This is the same limitation you have when using Dropbox/Google/OneDrive, only 1 of you owns the files and has to share them with the other. This complicates the organisation of your shared data. 

Just like that, on the local filesystem, whether shared in your home network, synced to your laptops, you will each be forced to look into each others folders to find the shared stuff. 

To ensure the local filesystem AND the online filecloud always allows direct access to the stuff you share with your partner, the easiest solution is to create a `third user` that owns a userfolder called `Shared`. On the local server filesystem, those shared files can simply be made accessible in _$HOME/Documents, Pictures, Desktop_ while actually being stored in `mnt/pool/users/Shared`. Your own data of each of you can be made accessible via `$HOME/yourname` and `$HOME/partnername`. Simple, clean and neat organisation of your data! 

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
The script prep-folderstructure.sh should not be used blindly. Or not at all. Only for inspiration. It will create the folder structure as described AND map those `Shared` documents and media folders to the server /home dir, replacing those personal folders for symlinks. Adjust at will before running it.
1. Get the script: 
`cd Downloads`
`wget https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/create_folderstructure.sh`
2. Before you run it, open it open the script in a text editor
   - Use the top commands and fix the permissions, change `asterix` to your user account.
   - Also make changes/remove parts you do not want.
3. Run the script via `bash create_folderstructure.sh`. Do not use sudo. if you get permission denied errrors, you have to fix those first. 
