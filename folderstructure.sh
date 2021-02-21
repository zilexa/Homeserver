#!/bin/bash
# Permissions can be fixed as follows (this makes sure the personal folder cannot be deleted by the main user, but gives full access to the main user to the contents of the folder. 
# sudo chown asterix:asterix $NAME
# sudo chmod u+rwx -R $NAME


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

# This folder will contain files of all users. Each folder is the private cloud of each user. These folders can be synced and/or easily accessed via apps. 
# Collections can be made available as subdirs within each User folder, via symlink (we will get there). 
# Differentiate between LOCAL users, which not necessarily have to be in your local network, but simply means these user folders will be treated like your own user folder: included in every backup mechanism.
# External users can be users for which your server IS their backup. 
mkdir -p /mnt/pool/Users/Local
mkdir -p /mnt/pool/Users/External
mkdir -p /mnt/pool/Users/Local/$NAME1
mkdir -p /mnt/pool/Users/Local/$NAME2

# If you are part of a family that has shared files, like a Music collection, Photo albums or even files on the Desktop on a shared laptop, 
# they can be hard to incorporate in your folder structure. I tried many ways, creating a seperate "Collections" folder, but eventually settled on creating a
# fictious user account "Asterix", the same name we use on our laptop as useraccount. 
# The benefit is that you maintain 1 single folder structure for all users, making backup organisation, filesystem organisation
# and local and online sharing just as easy as it is for all other users (1 method for all). 
mkdir -p /mnt/pool/Users/Local/Asterix
mkdir -p /mnt/pool/Users/Local/Asterix/Music
mkdir -p /mnt/pool/Users/Local/Asterix/Photos
mkdir -p /mnt/pool/Users/LocalAsterix/Desktop
mkdir -p /mnt/pool/Users/LocalAsterix/Downloads

# If you plan to download series/movies, create a seperate folder structure for it as the material is not unique and not bound to a user and does not require extensive backups. 
# Note the subdirs have been specifically chosen this way to work perfectly with common download tools. Recommend to stick to it exactly.
# NOTE: recently I chose to use the Asterix account for this, instead of a seperate /Media folder next to the /Users folder.
# This reduces the complexity of the folder structure to an absolute minium. 
# Note this does not mean tvseries/movies will be backupped. There is a common list of stuff that should never be backupped (OS system files that are scattered throughout user folders). 
# The TV dir is simply added to that list. 
mkdir -p /mnt/pool/Users/Local/Asterix/TV
mkdir -p /mnt/pool/Users/Local/Asterix/TV/TVshows
mkdir -p /mnt/pool/Users/Local/Asterix/TV/Movies
mkdir -p /mnt/pool/Users/Local/Asterix/TV/incoming
mkdir -p /mnt/pool/Users/Local/Asterix/TV/incoming/complete
mkdir -p /mnt/pool/Users/Local/Asterix/TV/incoming/incomplete
mkdir -p /mnt/pool/Users/Local/Asterix/TV/incoming/blackhole

# (optional) if you plan to use this server as workstation/desktop, you will use the Home/Username/ personal folders. 
# This means you need to map the fictious Asterix users' personal folders to the OS $HOME directory.. That's easy and pretty common on Linux: replace the folders for symbolic links.
# In case you already have data in those folders, move it to the pool: 
mv $HOME/Desktop/* /mnt/pool/Local/Users/Asterix/Desktop/
mv $HOME/Downloads/* /mnt/pool/Local/Users/Asterix/Downloads/
mv $HOME/Pictures/* /mnt/pool/Local/Users/Asterix/Photos/
mv $HOME/Music/* /mnt/pool/Local/Users/Asterix//Music/
mv $HOME/Videos/* /mnt/pool/Local/Users/Asterix/TV/

# Note I did not delete Documents, because we can use that folder as a 'container' for the 2 (or more) users sharing this workstation/desktop. 
# If you prefer you can delete Documents and replace it with a symbolic link to your user folder /Asterix/Documents.

# Now create several links, remember, the login account is actually Asterix in this example, so now we will link Asterix sub folders when available. 
# $HOME = a system variable and short for /home/asterix or whatever username you choose during OS installation. 
ln -s /mnt/pool/Collections/Music $HOME/
ln -s /mnt/pool/Collections/Photos $HOME/
ln -s /mnt/pool/Media $HOME/
ln -s /mnt/pool/Users/Local/$NAME1 $HOME/Documents/
ln -s /mnt/pool/Users/Local/$NAME2 $HOME/Documents/
ln -s /mnt/pool/Users/Local/Asterix/Downloads $HOME/
# Note, deleting or moving Desktop is not possible, the folder will be re-created immediately. 
# Temporarily change the location via a user config file, create the symlink, change it back. 
sudo sed -i -e 's+$HOME/Desktop+$HOME/Documents/Desktop+g' $HOME/.config/user-dirs.dirs
ln -s /mnt/pool/Users/Local/Asterix/Desktop $HOME/
sudo sed -i -e 's+$HOME/Documents/Desktop+$HOME/Desktop+g' $HOME/.config/user-dirs.dirs

# Now on a client PC, like a laptop that is shared by NAME1 and NAME2, add symlinks after setting up NFS shares (see NFS v4.2 guide)
# You only have to do this for folders with lots of files, as you don't want to fill up the limited space of your laptop.
# Other stuff like documents can be 2-way synced via Syncthing. 
#ln -s /mnt/Obelix/Collections/Photos/ $HOME/Photos/Obelix
#ln -s /mnt/Obelix/Collections/Music/ $HOME/Music/Obelix
#ln -s /mnt/Obelix/Media/ $HOME/Media/Obelix

