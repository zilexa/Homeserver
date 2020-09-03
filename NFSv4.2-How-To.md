notes: you will need to do this via terminal. 
You will edit a few text files in terminal via the nano text editor.
Saving your changes and exiting the text editor is done via 
CTRL+O (to save) and CTRL+X (to exit).

## Server:

### Install the NFS server app
`sudo apt -y install nfs-server`

### Register the folders to share via NFS
/etc/exports is 'the register' for shared folders. Only stuff listed in this file will be shared.
For example I want to share the folder /mnt/pool/Media via NFSv4.2 to client devices:

`sudo nano /etc/exports`
Add the following (single!) line:
`/mnt/pool/Media    192.168.88.0/24(rw,async,fsid=0,nohide,all_squash,no_subtree_check,anonuid=1000,anongid=1000)`
Each folder you want to share is a seperate line.

#### Now do the following to get this change activated:
```
sudo exportfs -a
sudo systemctl restart nfs-server
```


### Enforcing NFSv4.2 over v3, v4.1
- Stop the nfs-server
`sudo systemctl stop nfs-server`

- edit 2 files 
`sudo nano /etc/default/nfs-kernel-server`
`sudo nano /etc/default/nfs-common`

- In each file, add or if exist change the following lines to look like this, then save and close the file: 
```RPCNFSDOPTS="-N 2 -N 3"
RPCMOUNTDOPTS="--manage-gids -N 2 -N 3"
NEED_STATD="no"
NEED_IDMAPD="yes"
NEED_GSSD="no"
```

- Now start the service:
`sudo systemctl start nfs-server`

- Check if NFSv3.0 is disabled:
`sudo cat /proc/fs/nfsd/versions`
should show:
-2 -3 +4 +4.1 +4.2
Means -2 and -3 are disabled

- Now you can disable NFSv4.1
`sudo systemctl stop nfs-server
sudo nano /proc/fs/nfsd/versions`

- Change +4.1 to -4.1, save and close the file.

- `sudo systemctl start nfs-server`

- Check that 4.1 is disabled:
`sudo cat /proc/fs/nfsd/versions`
should show:
-2 -3 +4 -4.1 +4.2

Congrats! Clients will now only be able to connect via v4.2


## Client: 

### Install NFS (not NFS-server)
`sudo apt -y install nfs-common`

### Create a local folder, this folder will contain the shared folder of the server, you choose where.
`sudo mkdir -p /mnt/Obelix/Media`

### Now mount the server folder (as listed on the server in /etc/exports) to the local folder I just created.
`sudo mount -t nfs -o nfsvers=4,minorversion=2,proto=tcp,fsc,nocto 192.168.88.10: /mnt/Obelix/Media`

Note
Note you should NOT fill in the entire path of your servers etc/exports. That is a major difference compared to NFSv3. 
That is why in my example you see only the IP address: without the '/mnt/pool/Media'. 
