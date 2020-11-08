# How-To get NFSv4.2 up and running
Linux users can use NFS protocol to share files within their network. 
As there is zero overhead, this is extremely fast, only limited by your hardware and cables. 
Unfortunately, most if not all Linux systems by default use NFSv3.0 which comes with limitations. NFSv4.2 was released in 2015 but requires a different configuration than 99% of the online guides will show you.
I have spend lots of long nights figuring this out over the past few years and tonight I gave it another try and managed to get it working. 

#### Biggest benefit of NFSv4.2
Server-side file copy: if you are on your client device, and you move a 2GB file within the shared folder to a different location in the shared folder (e.g. subfolder), with NFSv3 and NFSv4.1 the file would first be copied (downloaded) to your client device and then copied to the subfolder (uploaded). Server-side-copy was introduced in NFSv4.2 among other useful features. 

The following has been tested on a clean Ubuntu Budgie 20.04.1 system and should work for Debian without modifications.

# Setup NFS v4.2 for your server and client devices

notes: you will need to do this via terminal. 
You will edit a few text files in terminal via the nano text editor.
Saving your changes and exiting the text editor is done via 
CTRL+O (to save) and CTRL+X (to exit).

## Server:

### Install the NFS server app
`sudo apt -y install nfs-server`


### Enforcing NFSv4.2 over v3, v4.1
- Stop the nfs-server
`sudo systemctl stop nfs-server`

- edit 2 files one by one:  
`sudo nano /etc/default/nfs-kernel-server`  
`sudo nano /etc/default/nfs-common`

- In each file, add or if exist change the following lines to look like this, then save and close the file: 
```
RPCNFSDOPTS="-N 2 -N 3"
RPCMOUNTDOPTS="--manage-gids -N 2 -N 3"
NEED_STATD="no"
NEED_IDMAPD="yes"
NEED_GSSD="no"
```

Optionally disable RPCbind, because NFSserver will start it, but NFSv4 does not use it:
```
sudo systemctl mask rpcbind.service
sudo systemctl mask rpcbind.socket
```

- Now start the service:
`sudo systemctl start nfs-server`

- Check if NFSv3.0 is disabled:
```
sudo cat /proc/fs/nfsd/versions`
```
should show: `-2 -3 +4 +4.1 +4.2` this means -2 and -3 are disabled

- Now you can disable NFSv4.1  
`sudo systemctl stop nfs-server`  
`sudo nano /proc/fs/nfsd/versions`

Change +4.1 to `-4.1`, save and close the file.

- Start the server again `sudo systemctl start nfs-server`

- Check that 4.1 is disabled:
`sudo cat /proc/fs/nfsd/versions`  
should show: `-2 -3 +4 -4.1 +4.2`

#### Congrats! Clients will now only be able to connect via v4.2

## Server: mount folders to a seperate dir + share them
Imagine folder /mnt with 6 subfolders. You might only want to share 2 of the subfolders, not its root /mnt.
NFSv4 requires you to share a root folder. This is different from older versions. To solve this, you are forced to create a root folder and 'link' your subfolders to that folder. 
This is NOT necessary if you will never share more than a single folder via NFS. 

- create /srv/nfs folder  
`sudo mkdir -p /srv`  
`sudo mkdir -p /srv/nfs`

- Create a folder for each subfolder you want to share. We will 'link' those folders to this location. In this example I want to share 2 folders: /mnt/pool/Local and /mnt/pool/Media.  
`sudo mkdir -p /srv/nfs/Local`  
`sudo mkdir -p /srv/nfs/Media`

- Now edit your fstab file..
`sudo nano /etc/fstab`

- ..and create the mounts by copy pasting the following, then save and close the file:
```
/mnt/pool/Local /srv/nfs/Local none rbind 0 0
/mnt/pool/Media /srv/nfs/Media none rbind 0 0
```

- now activate the mounts (note everything in /etc/fstab will be automatically mounted at boot):
`sudo mount -a`

#### Congrats, the folders you want to share are now also visible via a seperate root folder /srv/nfs which is what we will share.

### Register the folders to share via NFS
/etc/exports is 'the register' for shared folders. Only stuff listed in this file will be shared.
For example I want to share the folder /mnt/pool/Media via NFSv4.2 to client devices:
`sudo nano /etc/exports`  
Add the following line, note the IP address range might be different depending on your router configuration!:
```
/srv/nfs    192.168.88.0/24(rw,async,fsid=0,crossmnt,nohide,all_squash,no_subtree_check,anonuid=1000,anongid=1000)
/srv/nfs/Local    192.168.88.0/24(rw,async,fsid=1,crossmnt,nohide,all_squash,no_subtree_check,anonuid=1000,anongid=1000)
/srv/nfs/Media    192.168.88.0/24(rw,async,fsid=2,crossmnt,nohide,all_squash,no_subtree_check,anonuid=1000,anongid=1000)
```

#### Now do the following to get this change activated:
`sudo exportfs -a`  
`sudo systemctl restart nfs-server`  


#### Congrats! You have now disabled all versions of NFS except v4.2, you have linked your shared folders to a seperate folder and you have now shared them.


## Client: 
With NFS you have to mount the server path, there is no such thing as "scan and automatically disover all shared folders" as is with Apple or Windows. 
Here we go.

### Install NFS (not NFS-server)
`sudo apt -y install nfs-common`

### Create a local folder, this folder will contain the shared folder of the server, you choose where.
`sudo mkdir -p /mnt/Obelix`

### Now mount the server folder (as listed on the server in /etc/exports) to the local folder I just created.
`sudo mount -t nfs -o nfsvers=4,minorversion=2,proto=tcp,fsc,nocto 192.168.88.2: /mnt/Obelix`
Now go to that folder and see if you can access it, see your files. 

### make this mount permanent
Add the following line to fstab to mount the server add boot.  
`sudo nano /etc/fstab`  
Copy the following line, save and exit:  
`192.168.88.2:  /mnt/Obelix  nfs4  nfsvers=4,minorversion=2,proto=tcp,fsc,nocto  0  0`  

### test the permanent mount: 
First unmount, as the folder was already mounted 2 steps ago:  
`sudo umount /mnt/Obelix`  
Now mount the folder via fstab:  
`sudo mount -a --verbose`  

You should see something like this at the end: 
```
mount.nfs4: timeout set for Sun Sep 13 00:13:55 2020
mount.nfs4: trying text-based options 'minorversion=2,proto=tcp,fsc,nocto,vers=4,addr=192.168.88.2,clientaddr=192.168.88.20'
/mnt/Obelix              : successfully mounted
```

#### Congrats! It all worked.

Note:
Note you should NOT fill in the entire path of your servers etc/exports. That is a major difference compared to NFSv3. 
That is why in my example you see only the IP address: without the '/mnt/pool/...'. 
