During the Nightly maintenance, your system will scrub each BTRFS drive and check for errors. 
It is normal to see errors appearing after a year or so. For example, when you check your email notifications, you might see this: 

`
Scrub device /dev/sda (id 1) done
Scrub started:    Sun Dec 25 06:27:45 2022
Status:           finished
Duration:         1:53:14
Total to scrub:   965.07GiB
Rate:             109.78MiB/s
Error summary:    read=1412
  Corrected:      0
  Uncorrectable:  1412
  Unverified:     19939
` 
This is not scary, with other filesystems, the same could have happened unnoticed. Now at least you know and you can figure out which files are affected.
With BTRFS raid1, this will be automatically fixed during scub using the data on other drives (because data is duplicated and metadata is stored on 2 devices instead of just 1).
With BTRFS without raid1 option, metadata is duplicated (if you followed this guide) but of course stored on the same device, so there are less recovery options.
This is why we set up backups.

1. Find the affected files
Simply run this command, and make sure your window is wide enough to read the file path and filename: 
```
sudo journalctl --dmesg --grep "BTRFS warning"
```
Scroll through the whole list with SPACE bar, then scroll back slowly and make a note via Text Editor of the affected files.

2. Delete the files
Simply deleting the files (assuming you have them in your backup or you can simply let Sonarr/Radarr/Lidarr re-download them) solves the issue usually.

3. Restore the file from your snapshot or from a backup on a different file.
See the Backup guide for tips.

4. Run scrub again to verify there are no more issues. 
```
sudo btrfs scrub start -Bd /dev/sda  
```

