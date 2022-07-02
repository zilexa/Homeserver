
# Data migration 
To migrate data to your pool `/mnt/pool/` it is best and fastest to use `btrfs send | btrfs receive` if both source and destination use btrfs filesystem. Otherwise, always securily copy data using `rsync` or it's GUI version `grsync`.
***

### From any drive or folder, regardless of filesystem 
- _Moving files and folders from one drive to the other_  \
  You want to make sure files are correctly read and written, without read or write errors. For that, we have rsync. If you are copying lots of data while doing other activities, make sure to append `nocache`: 
  ```
  nocache rsync -axHAXE --info=progress2 --inplace --no-whole-file --numeric-ids  /media/my/usb/drive/ /mnt/pool-nocache
  ```
- _Moving files and folders to another folder on the same drive_ \
  The `mv` command is used to move or rename folders. But it doesn't include hidden files. This way it does:
  ```
  sudo find /source/folder -mindepth 1 -prune -exec mv '{}' /destination/folder \;   
  ```
  Use MergerFS cache? Copy files to the nocache pool `/mnt/pool-nocache` otherwise you end up filling your cache! You will still see all data in `/mnt/pool`.

***

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
3. And finally create a read-write snapshot, to make it usable, this will be the final destination:  
  ```
  sudo btrfs subvolume snapshot /destination/folder/readonlysnapshot /destination/folder/subvolumename
  ```
Then you can then delete the read-only snapshot using `sudo btrfs subvolume delete /destination/folder/readonlysnapshot`. 

***

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
 
