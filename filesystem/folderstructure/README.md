Folder Structure Recommendations

My folder structure is extremely simple, this supports easy backups and snapshots with a similar file structure: 

The root of my data (data disk array): 
/mnt/pool 

Contains a single folder: 
/mnt/pool/Users

Now I split 2 types of Users: Local (me, my partner, closest family) and External (Friends that I give cloud accounts). 
Local Users will be backupped, since this is the primary place where their data is stored. 
External Users: this is not their primary data location, they will most probably use my Homeserver as a backup. 

The full folder structure: 
/mnt/pool/Users/Local/Username1
/mnt/pool/Users/Local/Username2
/mnt/pool/Users/Local/Username3
...
/mnt/pool/Users/External/Username1
/mnt/pool/Users/External/Username2
...

Within a User folder: 
/mnt/pool/Users/Local/Username1/Photos
/mnt/pool/Users/Local/Username1/Music
/mnt/pool/Users/Local/Username1/Phone-Sync (special folder)
/mnt/pool/Users/Local/Username1/...(files and documents)


With 
On your local system, like a PC or even a laptop, I want to be able to access my files and shared files, even if I don't have internet or I am not at home.

Now consider (3) in combination with Dropbox/GoogleDrive/Onedrive: 
Only 1 user can have the files in her Drive account, and share it with the other. Access is limited to the Drive website or app.

5. I want to be able to share a local PC/laptop device and use it, where each has their own folder but also has access to those shared files.. on the local filesystem AND online via web/app.

To solve 3, 4, 5: I create a
