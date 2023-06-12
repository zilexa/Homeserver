
# Data migration 
To migrate data to your pool `/mnt/pool/` it is best and fastest to use `btrfs send | btrfs receive` if both source and destination use btrfs filesystem. Otherwise, always securily copy data using `rsync` or it's GUI version `grsync`.
***

### From any drive or folder, regardless of filesystem 
- _Copying files and folders from one drive to the other_  \
  You want to make sure files are correctly read and written, without read or write errors. For that, we have rsync. If you are copying lots of data while doing other activities, make sure to append `nocache`: 
  ```
  nocache rsync -axHAXES --info=progress2 --preallocate --inplace --numeric-ids /mnt/drives/cache/users/ /mnt/pool-nocache/users/
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
After you have verified the data, you can then delete the read-only snapshot using `sudo btrfs subvolume delete /destination/folder/readonlysnapshot`. 

***

### Verify your copied data
This is overkill and paranoia: btrfs has checksums build in. Rsync will verify checksums twice: a 2nd time after data is written (btrfs send/receive won't do that).  
But for very precious data to double-check all data is really identical to the source. 
- Fast method (only shows output if a difference is found):
  ```
  diff -qr /source/otherfolder/snapshot/ /destination/folder/snapshot/
  ```
- Checksum based (slower):
  ```
  rsync --dry-run -crv --delete /source/otherfolder/snapshot/ /destination/folder/snapshot/
  ``` 
  <sub>nothing will be deleted or modified. See info: [rsync manpage](https://linux.die.net/man/1/rsync)</sub>
  
***

### Fix ownership and permissions
When you created subvolumes (usually with `sudo`) and mountpoints (also with `sudo`) and played with moving snapshots around, you noticed you can only create, copy or move data in there with sudo?
This is normal, but you do need to fix the ownership and permissions before you can use your data normally, without sudo. 
--> I highly recommend to leave the top folders (`users` and `media`) owned by root so you or an application cannot delete those. Instead, apply the following to each folder inside those folders seperately. To do so: 
- ownership, notice you need to add (D) to also apply this change to hidden files/folders: 
  ```
  sudo chown -R ${USER}:${USER} /mnt/pool/users/name(D)
  ``` 
  Only change `name` and apply to command to each folder inside `users`. 
- permissions: 
  ```
  sudo chmod -R 755 /mnt/pool/users/name(D)
  ```
  Only change `name` and apply to command to each folder inside `users`. 

And do the same for your Media path: `/mnt/pool/media(D)`.

I highly recommend reading [this intro into Linux permissions](https://wise.wtf/posts/beginner-bits-linux-permissions/). this will fill the knowlegde gap that will otherwise come back and bite you. 
