# STEP 7: Server Backup Guide
Your docker subvolume folder (`mnt/drives/system/@docker`, mounted to `$HOME/docker`) and the subvolumes inside your `users` filesystem (mounted to `/mnt/pool/users`) or the underlying MergerFS drives contain essential data, critical for your server to run and for your users to stay happy. BTRFS allows you to create instant-snapshots of these subvolumes. Initially this will cost 0 extra space, until you start making changes in the original subvolume. 
Snapshots read-only by default, you can make them writeable via the `btrfs` command. Instead, best practice when you need to restore a subvolume is to simply create writeable snapshot of the read-only snapshot. To be able to do so, the tool btrbk is used to create snapshots, backups, archives and manage your retention policy. 

By creating backups, you double the amount of drives you need for your server. [Alternatively, look at Parity-based backups](https://github.com/zilexa/Homeserver/blob/master/Backups-guide/parity-backups.md).

## Timeline backups & offline archiving
[btrbk](https://digint.ch/btrbk) is the de-facto tool for backups of BTRFS subvolumes. It uses BTRFS native filesystem-level data replication and snapshot features. This means it is extremely fast and reliable. It supports everything from scheduled snapshotting, backing up to local or networked locations and archiving to local, networked or USB drives. 
- The btrbk.conf file contains 1) the subvolumes you want to snapshot 2) the location of the snapshots on the same drive and 3) (optional) the location of the backup drive. Besides that, it contains your retention policy for snapshots, backups and archives. 
- You will end up with a folder on your drives that contain timeline-like snapshots and a similar folder on your backup drive. 
- Periodically, you can connect a USB drive (see [Step 2 here](https://github.com/zilexa/Homeserver/tree/master/filesystem#step-21-prepare-drives) on how to prep the drive, including step 2.4) to archive your internal backup drive to the USB drive. 
- For a short intro into btrbk, [read this](https://wiki.gentoo.org/wiki/Btrbk). 


### Prequisities
- [Step 1B:Install Essentials](https://github.com/zilexa/Homeserver#step-1b-how-to-properly-install-docker-and-essential-tools) via prep-server.sh, this has been done: installed btrbk, downloaded the configuration files from this repository to [$HOME/docker/HOST/btrbk/](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/btrbk), configured the system with your SMTP account to sent emails using command `mail -s`. Added a manual mountpoint to fstab for your systemdrive and (can be mounted via `mount /mnt/drives/system` and created a folder `/mnt/drives/system/snapshots` for your docker subvolume snapshots. 

### 1. prepare
- As root, create a folder `snapshots` in the root of each filesystem (for example `/mnt/pool/users/snapshots` or if you use MergerFS `/mnt/drives/data1` etc). 
- Give it limited permissions. Without root, you want read access to this folder, that way, you can easily restore from a snapshot: `sudo chmod 655 /mnt/pool/users/snapshots`.
- Mount your internal backup drive `sudo mount /mnt/drives/backup1` and create a folder `system` and a folder `users`. 
- Edit the file [$HOME/docker/HOST/btrbk/btrbk.conf](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/btrbk), ensure all paths are correct. If you use MergerFS, you need a section for each underlying drive. The config is ready to go if you want to backup your `docker` subvolume and the subvolumes of each user, stored on a BTRFS filesystem (single or multiple underlying drives). 
- Ensure the retention policy for snapshots, backups and USB archive are OK for you.  


### 2. First-time run
First time, do a dryrun (simulation) first, no snapshots/backups are created. You can check the table if everything is correct.  
```
sudo btrbk dryrun -v
```
No errors + you are happy with the output table? Now run btrbk. Note this can take a long time, since your subvolumes will be duplicated to other drive(s).
```
sudo btrbk run --progress
```
Notice you can also run btrbk for a group (as set in the conf file), for example: `btrbk run users --progress `. 

### 3. Schedulings
Btrbk provides a script [$HOME/docker/HOST/btrbk/btrbk-mail.sh](https://github.com/zilexa/Homeserver/tree/master/docker/HOST/btrbk) that can mount your backup drives, run backups and send email notifications. The original file has been slightly modified. For example, your containers will be stopped, before backups are created.
1. Check the mounts at the beginning of the file, ensure all your required mounts to run backups are there. 
2. Run the script manually to test: `sudo bash $HOME/docker/HOST/btrbk/btrbk-mail.sh`
3. See the [Maintenance Guide](https://github.com/zilexa/Homeserver/tree/master/Maintenance-guide), to schedule the backup run. 


&nbsp;

