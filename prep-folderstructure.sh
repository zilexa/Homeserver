#!/bin/bash
#

echo "My folder structure might not be yours."
echo "1 drive pool (/mnt/pool) via MergerFS with my system drive (SSD 1TB) as fast cache and 2 HDDs as storage"
echo "1 drive pool (/mnt/archive) the same but without the system drive"
echo "only /mnt/pool is used by users, mnt/archive contains the same files and exists for MergerFS to purge the cache regularly."
echo " /mnt/pool/Collections --> My Photos & videos, ripped HQ music albums. Stuff to store and carefully backup forever."
echo "this data is usually to large to sync across devices."
echo "  "
echo "/mnt/pool/Users for all user data per user folder plus a 3rd virtual user for shared stuff on this pc"
echo "mnt/pool/Media for media downloads"
echo "I use my Ubuntu Budgie server also as home PC/workstation, together with my partner (1 user account)."
echo "I want all local folders (Documents, Downloads, Desktop, Music, Pictures) to be stored on the drive Pool."
echo "To do that, I replace the folders in $HOME for symbolic links."
echo "I also want them to be accessible via the personal cloud accounts of each PC user."
echo "Enter the name of the first workstation user (example: Monkey), followed by [ENTER]:"
read NAME1
echo USER1='"'$NAME1'"' >> /etc/environment
echo "Enter the name of the second workstation user (example: Fish), followed by [ENTER]:"
read NAME2
echo USER2='"'$NAME2'"' >> /etc/environment

# This folder will contain precious, long archived files that should be backupped offline, online and offsite. These are also usually to big to keep sync to multiple devices like laptops, phones.
mkdir -p /mnt/pool/Collections
mkdir -p /mnt/pool/Collections/Music
mkdir -p /mnt/pool/Collections/Photos

# This folder will contain files of all users. Each folder is the private cloud of each user. These folders can be synced and/or easily accessed via apps. 
# Collections can be made available as subdirs within each User folder, via symlink (we will get there). 
mkdir -p /mnt/pool/Users
mkdir -p /mnt/pool/Users/$NAME1
mkdir -p /mnt/pool/Users/$NAME2

# If you plan to download series/movies, create a seperate folder structure for it as the material is not unique and not bound to a user and does not require extensive backups. 
# Note the subdirs have been specifically chosen this way to work perfectly with common download tools. Recommend to stick to it exactly.
mkdir -p /mnt/pool/Media
mkdir -p /mnt/pool/Media/incoming
mkdir -p /mnt/pool/Media/incoming/complete
mkdir -p /mnt/pool/Media/incoming/incomplete
mkdir -p /mnt/pool/Media/incoming/blackhole
mkdir -p /mnt/pool/Media/TVshows
mkdir -p /mnt/pool/Media/Movies

# If 2 users share the same device (laptop) but use a single login account on that laptop, create a 3rd user with those specific folders (like Desktop)
# In this example, our login account name is Asterix so we use that as 3rd virtual user folder. 
# This is also the laptop account name I use for all our shared devices (desktop, laptop). 
# This way, you can have those folders like Desktop and Downloads on multiple devices and keep them in sync easily. 
mkdir -p /mnt/pool/Users/Asterix
mkdir -p /mnt/pool/Users/Asterix/Desktop
mkdir -p /mnt/pool/Users/Asterix/Downloads

# Now make /Asterix available as subdir for the users that use it. 
# This way, whenever a user accesses her private cloud, her laptop/workstation folders will be accessible easily via this subdir. 
ln -s /mnt/pool/Users/Asterix /mnt/pool/Users/$NAME1/
ln -s /mnt/pool/Users/Asterix /mnt/pool/Users/$NAME2/

# Now make /Collections available as subdir for the users that use it. 
# This way, whenever a user accesses her private cloud, her Collections folders will be accessible easily via this subdir. 
ln -s /mnt/pool/Collections /mnt/pool/Users/$NAME1/
ln -s /mnt/pool/Collections /mnt/pool/Users/$NAME2/
# Don't do this for the virtual 3rd user as that is not an actual person, it will not need to access stuff via personal cloud. 
# Asterix is a laptop login account and workstation pc login account

# (optional) if you plan to use this server as workstation/desktop, you will use the Home/Username/ personal folders. 
# Use the MergerFS Pool to store the Home folders of this local PC, by creating symbolic links from Pool to $HOME. First delete the folders.
rm -rf $HOME/Downloads
rm -rf $HOME/Pictures
rm -rf $HOME/Music
rm -rf $HOME/Videos

# Note I did not delete Documents, because we can use that folder as a 'container' for the 2 (or multiple) users sharing this workstation/desktop. 
# If you prefer you can delete Documents and replace it with a symbolic link to your user folder. 

# Now create several links, remember, the login account is actually Asterix so now we will link Asterix sub folders when available. 
ln -s /mnt/pool/Collections/Music $HOME/
ln -s /mnt/pool/Collections/Photos $HOME/
ln -s /mnt/pool/Media $HOME/
ln -s /mnt/pool/Users/$NAME1 $HOME/Documents/
ln -s /mnt/pool/Users/$NAME2 $HOME/Documents/
ln -s /mnt/pool/Users/Asterix/Downloads $HOME/

# For $HOME/Desktop, you need to log out first, start a terminal session, delete Desktop and then create the link. Good luck. 
# rm -rf $HOME/Desktop
# ln -s /mnt/pool/Users/Asterix/Desktop $HOME/
