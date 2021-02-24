# Folder Structure Recommendations

My folder structure is extremely simple, this supports easy backups and snapshots with a similar file structure. 

## System folder structure
### My mounts: 
- `/mnt/disks` --> physical disks
  - `/mnt/disks/data1`, `/mnt/disks/data2`, `/mnt/disks/data3`
  - `/mnt/disks/parity1`, optional: `/mnt/disks/parity2` 
  - `/mnt/disks/backup1`
- `/mnt/pool` --> the single access point to your data (disk array is mapped here). 
- `/mnt/btrfs-root` --> temporary, during initial setup and during nightly backup) 

### subvolumes: 
BTRFS snapshots of a subvolume exclude nested subvolumes. This way, we can exclude folders that should not be backupped or should be backupped separately: 
On the OS system SSD: 
- `/` --> root subvolume (in btrfs-root, also known as subvolid5)
- `/home` --> root subvolume, contains user data, backupped seperately (Ubuntu, Fedora default behavior).
- `$HOME/docker` --> root subvolume, contains non-expendable config and data of all Docker containers, backupped seperately.  
- `$HOME/.cache`, `/tmp` --> nested subvolumes, contains expendable temp files. Exclude.  
- `/system-snapshots` --> the location of snapshots. Exclude.
- On data disks, the only subvolume in the root subvolume is `/.snapshots` (the location of snapshots for snapraid-btrfs). 

### MAJOR benefit of subvolumes
The docker and home subvolumes are root subvolumes just like /. 
This allows you to first snapshot (backup) "/", and do a clean OS install on "/", mount docker and home via fstab and BAM you are instantly up and running. If you don't like the update, you can easily switch to a previous snapshot of /. 

### the Docker folder
- folder per container
- docker-compose.yml and .env files in the root of the folder.
- HOST folder: containing configs and scripts for maintenance, cleanup, backup. This way, you backup a single folder, /docker == equals backup of your complete server configuration. 

&nbsp;

## User data
The root of my data (data disk array) is `/mnt/pool` it contains a single folder: `/mnt/pool/Users`
Within this folder I differentiate between 2 types of Users, and each user will have their own UserName folder (a requirement for web access/identity management).

- `Users/Local` is the primary data storage for local users:
My partner, myself, parents, perhaps some very close relatives or friends. 

- `Users/External` is the secondary data storage for external users: 
Friends and family that need a backup of their data and would like to enjoy the benefits of your fast, reliable Homeserver/private cloud solution.

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

#### Phone-sync: 2-way sync
Folders on the users phone will be synced as subfolders within this directory. Note that 2-way sync, even if you use "send-only" or "receive-only", means _delete_ actions on the phone are also synced to the server. That is why this folder exists: it is not the backup of the phone folders. 
Example: 
- user syncs its smartphone/Pictures folder when the phone is on wifi & charging (at night). 
- They are synced to Username/Phone-Sync/Photos and immediately hardlinked* to Username/Photos/Phone-pics. 
- A hardlink means an extra 'chapter' in the 'index' of the filesystem has been made, but this chapter links to the same actual data (take up space only once). 
- Now, the user can delete the files on the phone, they will be deleted in `Phone-Sync` but still exist in ` Username/Photos/Phone-pics. 
* The script that does this isn't functional yet.. 


### Shared user for couples/families
The issue: My partner and I share photo albums, administrative documents etc. With Google Drive/DropBox/Onedrive, 1 user would own those files and share them with the other, but this only works in the online environment. The files are still stored in your folder. 
And on  a local (shared) home laptop which syncs her and your folders, or even on the server itself which you might use as PC you see the local filesystem: your partner won't see those shared files in her folder. This can be frustrating and annoying as she has to go find your dir with those files.

#### Solution
1. To keep the filesystem structure simple, we create a 3rd user, for example `asterix`. This is the same username as the server OS login user account for convenience. `Users/Local/Asterix` contains our photo albums, Music albums, documents etc. 
2. This folder is symlinked to `Users/Local/Myusername` and `Users/Local/Herusername`. A symlink makes it appear as if the folder is inside those folders but in reality it isn't. It is a redirect, without the user noticing. Now both users have access to shared stuff!
4. Extra benefit: on a shared home laptop, the local `Documents` folder of that laptop has `Myusername` and `Herusername` mounted into it (network shares). This allows easy and WAF-friendly access to files. And of course that symlinked Asterix/Documents folder will be there as well, in each users folder!
3. In a similar way. `Users/Local/Asterix/Photo Albums` is mounted inside the shared home laptop `Pictures` folder for quick and easy access. Now you can have local stuff in `Pictures` (handy if no internet) and also access the servers Photo Albums that you share. 

4. Note that private cloud solutions such as Nextcloud and FileRun won't allow access to symlinked folders, since each user access is tied to its own folder. 
In the Docker Compose file, you can see how to work around this issue, by mapping `Users/Local/Asterix` into the filesystem of the (Nextcloud or Filerun) container. 

## Action to take
I hope this makes sense. The script prep-folderstructure.sh will create the folder structure as described AND map those `asterix` documents and media folders to the server /home dir, replacing those personal folders for symlinks. Adjust at will before running it. 

