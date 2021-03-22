# Migrate data to your server & Folder Structure Recommendations

## 1. Data migration 
### 1.1 Moving files to your server
- To copy files from existing disks, connect them via USB. 
- Copy files to the nocache pool, `/mnt/pool-nocache` otherwise you end up filling your SSD!
- While copying via the file manager is an option I highly recommend using rsync as it will verify each disk read and write action, to ensure the files are copied correctly. Also it includes options to have 100% identical copy with all of your files metadata and attributes. This is the recommended command: 

`nocache rsync -axHAXE --info=progress2 --inplace --no-whole-file --numeric-ids  /media/my/usb/drive/ /mnt/pool-nocache`
- Alternatively, if you want to be able to do other things, interact with the filesystem or allow other apps to interact with the filesystem, use `nocache`, it has been installed via the server setup script: 

`nocache rsync -axHAXE --info=progress2 --inplace --no-whole-file --numeric-ids  /media/my/usb/drive/ /mnt/pool-nocache`
- You can also install the rsync app: `sudo apt install grsync`. 

### 1.2 Move files within your filesystem
To move files within a subvolume, copy them first, note this action will be instant on btrfs! Files won't be physically moved: 
`cp --reflink=always /my/source /my/destination`
Then when you are satisfied, delete the source folder/files. 
Alternatively, you can use the rename/move command `mv /my/source /my/destination` to rename or move files/folders. It will also be instant. 

## 2 Folder Structure Recommendations
My folder structure is extremely simple, this supports easy backups and snapshots with a similar file structure. 
Note I rely heavily on the flexibility and portability of btrfs subvolumes. 
For example, the docker and home subvolumes are root subvolumes just like /. This allows you to quickly restore the state of your docker applications to any point in time for which snapshot exists. Or you could even re-install your system, mount the docker subvolume and be back online immediately. 

### 2.1 System folder structure
When a BTRFS snapshot is made of a subvolume, its nested subvolumes are excluded. This way, we can exclude folders that should not be backupped or should be backupped separately, with a different cadence or a different retention policy.  

On the OS system SSD: 
- `/` --> root subvolume (in btrfs-root, also known as subvolid5)
- `/home` --> root subvolume, contains user data, backupped seperately (Ubuntu, Fedora default behavior).
- `$HOME/docker` --> root subvolume, contains non-expendable config and data of all Docker containers, backupped seperately.  
- `$HOME/.cache`, `/tmp` --> nested subvolumes are excluded when the parent subvol is snapshotted. These folders contain expendable data, should be excluded.  
- `/system-snapshots` --> the location of snapshots. Exclude.\

**About the Docker subvolume**:\
**This folder is precious and non-expendable! Will be backupped to backup disk just like your system disk and home folder.**
- a folder per container for app data/config data. 
- docker-compose.yml and .env files in the root of the folder.
- HOST folder: containing configs and scripts for maintenance, cleanup, backup. This way, you backup a single folder, /docker == equals backup of your complete server configuration. 

### 2.2 Disk mounts: 
- `/mnt/disks` --> physical disks
  - `/mnt/disks/ {data1, data2, data3}`
  - `/mnt/disks/parity1` 
  - `/mnt/disks/backup1` mounted only during backup run. 
- `/mnt/pool` --> the union of all files/folders on cache/data disks. the single access point to your data.

**Helper folders:**
- `/mnt/pool-nocache` --> the union but excluding the cache, required to offload the cache on a scheduled basis. 
- `/mnt/pool-backup` --> the union of cache/data disk backup snapshots on backupdisk. They are seperately backupped on the backupdisk. Not auto-mounted. Create this mount yourself when needed. 
- `/mnt/btrfs-root` --> used during initial setup and during nightly backup. Not auto-mounted.

### 2.3. Data folder structure
In the mountpoint of each cache/data disk, create the following subvolumes (for example, `cd /mnt/disks`, `sudo btrfs subvolume create data1/Users`: 
- `/Users` personal, non-expendable precious userdata. Protected via parity _and_ backupped to backup disk. 
- `/TV` non-personal, expendable tv media and downloads. Protected via parity, not backupped. 
- `/Music` non-personal, semi-expendable music files. Protected via parity, backup is a choice, if you have enough space. 
- `/.snapraid` contains the snapraid content file.
- additionally: `/data/Media/TV/incoming/incomplete` is a nested subvolume and should have `chattr -R +C incomplete` applied to it from its parent folder.\Reason: Downloaded files can be heavily fragmented. The torrent client can be set to download to `incomplete` and move files to `complete` when finished. By having a subvol for incomplete, files will be newly created (instead of just updating the index table) in complete. Zero fragmentation!

**When mounting the MergerFS pool, the folders (subvolumes behave just like folders) on the cache/datadisks will appear unionised inside `/mnt/pool`:**\
`mnt/pool/Users`, `mnt/pool/TV` and `/mnt/pool/Music`.  

&nbsp;

## 3. Extras 
### 3.1 Sharing data locally
NFSv4.2 is the fastest network protocol, allows server-side copy just like more common smb/samba and works on all OS's, although only for free on Mac and Linux. 
I only use this to share folders that are too large to actually sync with my laptop. For example photo albums. To sync files to laptops/PCs, Syncthing is the recommended application (installed via docker). 

## 3.2 Sharing files between partners/family with a structure that supports online access for all
The issue: My partner and I share photo albums, administrative documents etc. With Google Drive/DropBox/Onedrive, 1 user would own those files and share them with the other, but this only works in the online environment. The files are still stored in your folder. 
But your partner won't see those files on the local filesystem of your laptop, PC, workstation or server: only if she uses the web application (FileRun or NextCloud). As you will prefer to use the local files directly, this can be frustrating and annoying as she has to go find your folder with those files.

#### Solution
1. To keep the filesystem structure simple, we create a 3rd user, for example `asterix`. This is the same username as the server OS login user account for convenience. `Users/Asterix {Documents, Desktop, Photos}` contains our shared photo albums, shared documents etc. 
2. This folder is _bind mounted_ into to `Users/Myusername` and `Users/Herusername`. By mounting this folder in both locations, both have access as if it is their folder and Docker applications will work well with this solution (FileRun, Nextcloud, symlink won't work). 
3. Each one of our user folders is symlinked into `$HOME`.
4. `Asterix/Documents` is also symlinked to `$HOME`, replacing the existing Documents folder. 
5. In a similar way. `Asterix/Photos` is mounted in `$HOME`, replacing the Pictures folder. 
6. Extra benefit: on a shared home laptop, you can syncthing the Documents and username folders, so that the laptop has an offline copy. You can mount the larger folders like Photos but also Media via NFS, allowing the same folder structure in $HOME on your laptop as on your server! 

## Action to take
I hope this makes sense. The script prep-folderstructure.sh will create the folder structure as described AND map those `asterix` documents and media folders to the server /home dir, replacing those personal folders for symlinks. Adjust at will before running it. 
