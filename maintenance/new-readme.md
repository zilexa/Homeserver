Using Ubuntu and most of my apps running via Docker Compose, with MergerFS tiered caching with an SSD, my harddisks are spinned down most of the time. 
At night, 3AM, I perform the following actions via cron, 1-5 indicate the preferred order of execution:
Non sudo: 
- (1) Delete watched tv content 2 weeks after it has been watched. 
- (2) Cleanup files unmodified for 30 days: move from SSD to a subset of the pool /w only harddisks.
- (3) perform actions for my fileserver (FileRun, like Nextcloud but much faster and less non-filemanagement related features), precache thumbnails for new files and such. 
- (4) Snapraid-btrfs-runner to protect the subvolume containing tv/music content per disk (it is the largest, I don't have space on backup disk for that, since it's expendable data). 
Then, 3.20AM, (becausse disks spindown after 20min) the following starts. 
Sudo:
- (5) btrbk run to create snapshots & backups of my most valuable system & user data subvolumes to internal disk and, if attached, external disk. 
To make sure the backup task does not actually start while the other stuff is still running, the other stuff does touch /tmp/maintenance-is-running at the start of the script and removes that file at the end. The backup script has a sleep command to wait for that file to be gone, before running the btrbk command. 

