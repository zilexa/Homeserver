#!/bin/bash
# Permissions can be fixed as follows (this makes sure the personal folder cannot be deleted by the main user, but gives full access to the main user to the contents of the folder. 
# sudo chown asterix:asterix $NAME
# sudo chmod u+rwx -R $NAME

echo "Enter the name of the first workstation user (example: Your first name), followed by [ENTER]:"
read NAME1
echo USER1='"'$NAME1'"' >> /etc/environment
echo "Enter the name of the second workstation user (example: Your partners name), followed by [ENTER]:"
read NAME2
echo USER2='"'$NAME2'"' >> /etc/environment

# This folder will contain files of all users. Each folder is the private cloud of each user. These folders can be synced and/or easily accessed via apps. 
# Collections can be made available as subdirs within each User folder, via symlink (we will get there). 
# Differentiate between LOCAL users, which not necessarily have to be in your local network, but simply means these user folders will be treated like your own user folder: included in every backup mechanism.
# External users can be users for which your server IS their backup. 
mkdir -p /mnt/pool/Users/{Local,External}
mkdir -p /mnt/pool/Users/Local/$NAME1
mkdir -p /mnt/pool/Users/Local/$NAME2

# If you are part of a family that has shared files, like a Music collection, Photo albums or even files on the Desktop on a shared laptop, 
# they can be hard to incorporate in your folder structure. I tried many ways, creating a seperate "Collections" folder, but eventually settled on creating a
# fictious user account "Asterix", the same name we use on our laptop as useraccount. 
# The benefit is that you maintain 1 single folder structure for all users, making backup organisation, filesystem organisation
# and local and online sharing just as easy as it is for all other users (1 method for all). 
mkdir -p /mnt/pool/Users/Local/Asterix/{Documents,Photos,Desktop,Downloads}


# If you plan to download series/movies, create a seperate folder structure for it as the material is not unique and not bound to a user and does not require extensive backups. 
# Note the subdirs have been specifically chosen this way to work perfectly with common download tools. Recommend to stick to it exactly.
# NOTE: recently I chose to use the Asterix account for this, instead of a seperate /Media folder next to the /Users folder.
# This reduces the complexity of the folder structure to an absolute minium. 
# Note this does not mean tvseries/movies will be backupped. There is a common list of stuff that should never be backupped (OS system files that are scattered throughout user folders). 
# The TV dir is simply added to that list. 
mkdir -p /mnt/pool/Media/Music
mkdir -p /mnt/pool/Media/TV{Series,Movies,incoming}
mkdir -p /mnt/pool/Media/TV/incoming/{incomplete,complete,blackhole}

# (optional) if you plan to use this server as workstation/desktop, you will use the Home/Username/ personal folders. 
# This means you need to map the fictious Asterix users' personal folders to the OS $HOME directory.. That's easy and pretty common on Linux: replace the folders for symbolic links.
# In case you already have data in those folders, move it to the pool: 
mv $HOME/Documents/* /mnt/pool/Local/Users/Asterix/Documents/
mv $HOME/Desktop/* /mnt/pool/Local/Users/Asterix/Desktop/
mv $HOME/Downloads/* /mnt/pool/Local/Users/Asterix/Downloads/
mv $HOME/Pictures/* /mnt/pool/Local/Users/Asterix/Photos/
mv $HOME/Music/* /mnt/pool/Media/Music/
mv $HOME/Videos/* /mnt/pool/Media/TV/

# Note I did not delete Documents, because we can use that folder as a 'container' for the 2 (or more) users sharing this workstation/desktop. 
# If you prefer you can delete Documents and replace it with a symbolic link to your user folder /Asterix/Documents.

# Now create several links, remember, the login account is actually Asterix in this example, so now we will link Asterix sub folders when available. 
# $HOME = a system variable and short for /home/asterix or whatever username you choose during OS installation. 
ln -s /mnt/pool/Media/Music $HOME/
ln -s /mnt/pool/Media/TV $HOME/
ln -s /mnt/pool/Users/Local/$NAME1 $HOME/
ln -s /mnt/pool/Users/Local/$NAME2 $HOME/
ln -s /mnt/pool/Users/Local/Asterix/Documents $HOME/
ln -s /mnt/pool/Users/Local/Asterix/Desktop $HOME/
ln -s /mnt/pool/Users/Local/Asterix/Downloads $HOME/
ln -s /mnt/pool/Local/Users/Asterix/Photos/ $HOME/

# Note, deleting or moving Desktop is not possible, the folder will be re-created immediately. 
# Temporarily change the location via a user config file, create the symlink, change it back. 
sudo sed -i -e 's+$HOME/Desktop+$HOME/Documents/Desktop+g' $HOME/.config/user-dirs.dirs
ln -s /mnt/pool/Users/Local/Asterix/Desktop $HOME/
sudo sed -i -e 's+$HOME/Documents/Desktop+$HOME/Desktop+g' $HOME/.config/user-dirs.dirs
# Move Templates folder into Documents because it does not make sense to be outside it. 
sudo sed -i -e 's+$HOME/Templates+$HOME/Documents/Templates+g' $HOME/.config/user-dirs.dirs
mv $HOME/Templates $HOME/Documents/
# Disable Public folder because nobody uses it. 
sudo sed -i -e 's+$HOME/Public+$HOME+g' $HOME/.config/user-dirs.dirs
rm -rf $HOME/Public
# Rename Pictures to Photos
sudo sed -i -e 's+$HOME/Pictures+$HOME/Photos+g' $HOME/.config/user-dirs.dirs
# Rename Videos to TV 
sudo sed -i -e 's+$HOME/Videos+$HOME/TV+g' $HOME/.config/user-dirs.dirs

# after setting up NFS shares (see NFS v4.2 guide), you can mount the folders that are too large for the laptop/client devices:
# Other stuff like documents can be 2-way synced via Syncthing. 
#ln -s /mnt/servername/Asterix/Photos $HOME/
#ln -s /mnt/servername/Media $HOME/
