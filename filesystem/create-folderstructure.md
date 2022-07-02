
# Create your datapools
At this point you might want to take break and read the Folder Structure Recommendations first. 

## Step 1: Create the basics of your storage folder structure
- Instead of accessing your data directly via `/mnt/drives/data0` etc, it is recommended to have a single path for your data and either map multiple drives in subfolders (Option 1) or pool drives on that path (Option 2 and 3). 
    ```
    sudo mkdir -p /mnt/pool/{users, media}
    ```
- Note if you went for Option 2 (MergerFS with cache) you also need to create `/mnt/pool-nocache`, this will be your MergerFS pool, excluding your SSD cache, so that you have a path to offload the SSD to. 


## Step 2: Create subvolumes
- Each filesystem should have at least 1 subvolume. Subvolumes are the special folders of BTRFS that can be snapshotted and securily copied/transmitted to other drives or locations (for backup purposes). This guide assumes 2 types of data:  \

- _users_
  contains per-user folders, each user folder will contain all data of that user (documents, photos etc). Note that if you have family content such as your photo collection, this can be stored in a family-user account (for example user "Shared"). This way, each user still has their own data but also access to a Shared folder. 
- _media_
  not user-specific and often generally available such as Downloads; Movies, TV Shows, Music Albums. 

1. decide which one of your drives or btrfs raid1 filesystems (`data0`, `data1` etc) will contain USER or MEDIA data. 
2.  Create a subvolume (needs to be done per filesystem): 
```sudo btrfs subvolume create /mnt/disks/data0/Media``` 
```sudo btrfs subvolume create /mnt/disks/data1/Users``` 
3. If you use MergerFS, make sure to create subvolumes on each drive! Because MergerFS will not create subvolumes for you, only regular folders. 

&nbsp;
## Step 3: Add pools to FSTAB
Now that you have subvolumes, you can mount the subvolumes to the different pools by editing `/etc/fstab` again: 
```
sudo nano /etc/fstab
```
The goal is to have all your data accessible for users and applications or cloud services via `/mnt/pool/media` and `mnt/pool/users`, regardless of underlying drives. Also, snapshot/backup folders will not be visible here as you want to isolate those instead of exposing them to users/applications. 

### _Option 1: single drive per datatype or BTRFS1_
Mount your drive or raid1 filesystem for media to `/mnt/pool/media` and your drive or raid1 filesystem for users to `mnt/pool/users`.  \
```
UUID=8e9f178a-e531-40ce-87a9-801aa11aa4ea /mnt/pool/media btrfs defaults,noatime,compress-force=zstd:2,subvol=media 0 0
UUID=0187bc8c-4188-4b25-b4d6-46dcd655c3ce /mnt/pool/users btrfs defaults,noatime,compress-force=zstd:2,subvol=users 0 0
```
Notes
> - The `subvol=` option is important here!
> - Note`UUID=` is the UUID of the drive, easy to find as it should already be listed in your fstab (see Step 5).
> - In case of RAID1, just use the UUID of the first drive to mount the entire raid1 filsystem.


### _Option 2: multiple drives pooled via MergerFS_
If you have multiple drives that need to be pooled, you merge them via MergerFS. for example:  \
`/mnt/disks/data1/users` and `/mnt/disks/data2/users` to `mnt/pool/users` \
`/mnt/disks/data0/media` and `/mnt/disks/data3/media` to `/mnt/pool/media`  \
To merge/pool the Users drives and the Media drives, you simply add a line in FSTAB for each desired pool, using MergerFS as filesystem: 
```
/mnt/disks/data1/Users:/mnt/disks/data2/Users /mnt/pool/Users fuse.mergerfs ...
/mnt/disks/data0/Media:/mnt/disks/data3/Media /mnt/pool/Media fuse.mergerfs ... 
``` 
1. This is an incomplete example, go to [the example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) and copy the first MergerFS example line into your fstab.
2. Change the paths of your drive to reflect your situation.
3. You can optionally change a few arguments to your desire: 
  - FSNAME: a name to identify your pool for the OS. Not important.
  - MINFREESPACE: when this threshold has been reached, the disk is considered full and depending on the MergerFS policy it will write to the next drive.
  - POLICY: MergerFS will follow a _Least Free Space (LFS)_ policy; filling up disk by disk starting with the first disk. This way, you always know where your data is stored. You can also choose a different policy for example to fill each drive equally by always selecting the drive with the _most free space (MFS)_ and there are lots of other policies. [The policies are documented here](https://github.com/trapexit/mergerfs#policy-descriptions). No need to change unless you know what you are doing.
  - The rest of the long list of arguments have carefully been chosen for high performance while maintaining stability. 

#### Optional MergerFS with Tiered Cache_
If you use MergerFS [Tiered Caching](https://github.com/zilexa/Homeserver/blob/master/filesystem/FILESYSTEM-EXPLAINED.md#mergerfs-bonus-ssd-tiered-caching) do the following: 
1. Follow the examples for MergerFS in the [example fstab](https://github.com/zilexa/Homeserver/blob/master/filesystem/fstab) 
2. Make sure to add `/mnt/disks/cache/users` and/or `/mnt/disks/cache/media` as _first drive_ in each MergerFS line. 
3. Each MergerFS pool should also have a corresponding "no-cache" pool containing only the harddisks and mounted to `/mnt/pool-nocache/users` or `/mnt/pool-nocache/media`. Through Scheduling (see Maintenance guide) you can configure offloading your cache drive by copying its contents (of the drive, not the pool) to the subfolders of `mnt/pool-nocache`. 
4. Realize that all data in `/mnt/pool/no-cache` is also in `/mnt/pool/` since one is a subset of the other. 

#### Why do we mount subvolumes instead of the root of the drive?
--> In `/mnt/pool/` you only want to see Users and Media. The Backup Guide will require additional folders in the root of each drive (for snapshots and/or parity). As a best practice, you should only expose folders to users and applications that must be exposed. Exposing your backup/snapshots folder serves no purpose. 
