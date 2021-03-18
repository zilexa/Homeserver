# Folder Structure Recommendations

My folder structure is extremely simple, this supports easy backups and snapshots with a similar file structure. 

## 1. System folder structure
### My mounts: 
- `/mnt/disks` --> physical disks
  - `/mnt/disks/ {data1, data2, data3}`
  - `/mnt/disks/parity1` 
  - `/mnt/disks/backup1`
- `/mnt/pool` --> the single access point to your data (disk array is mapped here). 
- `/mnt/btrfs-root` --> temporary, during initial setup and during nightly backup) 

### subvolumes: 
When a BTRFS snapshot is made of a subvolume, its nested subvolumes are excluded. This way, we can exclude folders that should not be backupped or should be backupped separately, with a different cadence or a different retention policy.  

On the OS system SSD: 
- `/` --> root subvolume (in btrfs-root, also known as subvolid5)
- `/home` --> root subvolume, contains user data, backupped seperately (Ubuntu, Fedora default behavior).
- `$HOME/docker` --> root subvolume, contains non-expendable config and data of all Docker containers, backupped seperately.  
- `$HOME/.cache`, `/tmp` --> nested subvolumes are excluded when the parent subvol is snapshotted. These folders contain expendable data, should be excluded.  
- `/system-snapshots` --> the location of snapshots. Exclude.
On data disks: 
`/data` and `/.snapraid` both root subvolumes. That latter contains the snapraid content file.

### MAJOR benefit of subvolumes
The docker and home subvolumes are root subvolumes just like /. 
This allows you to first snapshot (backup) "/", and do a clean OS install on "/", mount docker and home via fstab and BAM you are instantly up and running. If you don't like the update, you can easily switch to a previous snapshot of /. 

### the Docker folder
- folder per container
- docker-compose.yml and .env files in the root of the folder.
- HOST folder: containing configs and scripts for maintenance, cleanup, backup. This way, you backup a single folder, /docker == equals backup of your complete server configuration. 

&nbsp;

## 2. User-specific data and non-personal data
The root of my data (data disk array) is `/mnt/pool`, it contains 2 folders:
- `/mnt/pool/Users` <--- User-specific data.
- `/mnt/pool/Media` <--- non-personal data: tvshow and movie downloads, AudioCD rips. This folder is shared in my local network via NFSv4.2.

### Non-Personal Data
The Media folder contains _expendable_ data such as TV shows, Movies and AudioCD rips: 
- /mnt/pool/Media/TV {Series, Movies, incoming} 
- /mnt/pool/Media/Music {CD Albums, Various} 
This Media folder is shared to laptops in my LAN via NFSv4.2, the fastest network share protocol (also allows server-side copy since v4.2!). 
`Media/TV` is not part of my _main_ backup strategy: it won't be backupped to `/mnt/disks/backup1` since it does not contain personal data. Only the relevant subvolumes of the OS-system SSD and the /mnt/pool/Users folder are backupped with a timeline on that disk.  
The data is still very well protected via SnapRAID and data can easily be restored in case of a disk failure. It just won't take up storage on the backup drive, unless you choose to (and have enough free space). 

### User-Specific Data
Within this folder I differentiate between 2 types of Users, and each user will have their own UserName folder (a requirement for web access/identity management).

- `Users/Local` is the primary data storage for local users:
My partner, myself, parents, perhaps some very close relatives or friends. Your cloud solution is their primary data storage just like it is your primary storage.

- `Users/External` is the secondary data storage for external users: 
Friends and family that have their own primary storage (perhaps with a public provider) that need a backup of their data and would like to enjoy the benefits of your fast, reliable Homeserver/private cloud solution.

Example: 
```
Users/Local/Username1
Users/Local/Username2
Users/Local/Username3
...
Users/External/Username1
Users/External/Username2
...
```

Example of a user folder contents (entirely up to the user):  
```
Username1/Photos
Username1/Music
Username1/Phone-Sync (special folder)
Username1/Ebooks
Username1/[several document folders]
```

## 3. Shared user for couples/families
The issue: My partner and I share photo albums, administrative documents etc. With Google Drive/DropBox/Onedrive, 1 user would own those files and share them with the other, but this only works in the online environment. The files are still stored in your folder. 
But your partner won't see those files on the local filesystem of your laptop, PC, workstation or server: only if she uses the web application (FileRun or NextCloud). As you will prefer to use the local files directly, this can be frustrating and annoying as she has to go find your folder with those files.

#### Solution
1. To keep the filesystem structure simple, we create a 3rd user, for example `asterix`. This is the same username as the server OS login user account for convenience. `Users/Local/Asterix {Documents, Desktop, Photos}` contains our shared photo albums, shared documents etc. 
2. This folder is _bind mounted_ into to `Users/Local/Myusername` and `Users/Local/Herusername`. By mounting this folder in both locations, both have access as if it is their folder and Docker applications will work well with this solution (FileRun, Nextcloud, symlink won't work). 
3. Each one of our user folders is symlinked into `$HOME`.
4. `Asterix/Documents` is also symlinked to `$HOME`, replacing the existing Documents folder. 
5. In a similar way. `Asterix/Photos` is mounted in `$HOME`, replacing the Pictures folder. 
6. Extra benefit: on a shared home laptop, you can syncthing the Documents and username folders, so that the laptop has an offline copy. You can mount the larger folders like Photos but also Media via NFS, allowing the same folder structure in $HOME on your laptop as on your server! 

## Action to take
I hope this makes sense. The script prep-folderstructure.sh will create the folder structure as described AND map those `asterix` documents and media folders to the server /home dir, replacing those personal folders for symlinks. Adjust at will before running it. 

When done, continue with the main guide to [Step 3 - Prepare server & Docker.](https://github.com/zilexa/Homeserver#step-3-prepare-server-and-docker)

