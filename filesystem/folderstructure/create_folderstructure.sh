#!/bin/bash
# Permissions can be fixed as follows (this makes sure the personal folder cannot be deleted by the main user, but gives full access to the main user to the contents of the folder. 
# sudo chown asterix:asterix $NAME
# sudo chmod u+rwx -R $NAME
echo "==========================================================================================================="
echo "If you are part of a family that has shared files, like Photo albums, Documents, files on Desktop, Downloads..." 
echo "they can be hard to incorporate in your folder structure." 
echo "Solve this by creating an extra user folder, besides the folders of you and your partner. Just call it Shared or come up with a funky name."
echo "This script will create the user folders for you, your partner and that made up user." 
echo "Next, it will create the common personal folders inside the made up user folder." 
echo "Then it will replace the common personal documents in your Home folder with links to this virtual user in your pool." 
echo "This virtual user folder can be seen as the shared folder, you can map it via Docker Compose (FileRun, see example in compose) to both of your user folders. 
echo "You can even share tis virtual user folder over the LAN network via SMB or NFS." 
echo " "
echo "The benefit is that you maintain 1 single folder structure for all users, making backup organisation, filesystem organisation" 
echo "and local and online sharing just as easy as it is for all other users (1 method for all)." 
echo "==========================================================================================================="
read -p "Read between the lines then HIT CTRL+C to stop the script here or hit ENTER to start, you will be asked to enter names.. "
echo "==========================================================================================================="
echo "Enter your name followed by ENTER. First letter capital, this will be /mnt/pool/Users/Yourname and a symlink will be added to the $HOME folder:"
read NAME1
echo USER1='"'$NAME1'"' >> /etc/environment
echo "-----------------------------------------------------------------------------------------------------------"
echo "Now enter the name of your partner or other person that can use this workstation, same actions will be performed:"
read NAME2
echo USER2='"'$NAME2'"' >> /etc/environment
echo "-----------------------------------------------------------------------------------------------------------"
echo "Now come up with a name for the shared user folder, for example Batman." 
echo "This workstation common personal folders (Desktop, Documents etc) will be moved to the pool and symlinked back to the $HOME folder:"
read NAME2
echo SHAREDUSER='"'$SHAREDUSER'"' >> /etc/environment

# This folder will contain files of all users. Each folder is the private cloud of each user. These folders can be synced and/or easily accessed via apps. 
# Collections can be made available as subdirs within each User folder, via symlink (we will get there). 
mkdir -p /mnt/pool/Users/$NAME1
mkdir -p /mnt/pool/Users/$NAME2
mkdir -p /mnt/pool/Users/$SHAREDUSER


mkdir -p /mnt/pool/Users/$SHAREDUSER/{Documents,Photos,Desktop,Downloads}


# If you plan to download series/movies, create a seperate folder structure for it as the material is not unique and not bound to a user and does not require extensive backups. 
# Note the subdirs have been specifically chosen this way to work perfectly with common download tools. Recommend to stick to it exactly.
# NOTE: recently I chose to use the Asterix account for this, instead of a seperate /Media folder next to the /Users folder.
# This reduces the complexity of the folder structure to an absolute minium. 
# Note this does not mean tvseries/movies will be backupped. There is a common list of stuff that should never be backupped (OS system files that are scattered throughout user folders). 
# The TV dir is simply added to that list. 
mkdir -p /mnt/pool/Music
mkdir -p /mnt/pool/TV{Series,Movies,incoming}
mkdir -p /mnt/pool/TV/incoming/{complete,blackhole}
btrfs subvolume create /mnt/pool/TV/incoming/incomplete

# (optional) if you plan to use this server as workstation/desktop, you will use the Home/Username/ personal folders. 
# This means you need to map the fictious Asterix users' personal folders to the OS $HOME directory.. That's easy and pretty common on Linux: replace the folders for symbolic links.
# In case you already have data in those folders, move it to the pool: 
mv $HOME/Documents/* /mnt/pool/Users/$SHAREDUSER/Documents/
mv $HOME/Desktop/* /mnt/pool/Users/$SHAREDUSER/Desktop/
mv $HOME/Downloads/* /mnt/pool/Users/$SHAREDUSER/Downloads/
mv $HOME/Pictures/* /mnt/pool/Users/$SHAREDUSER/Photos/
mv $HOME/Music/* /mnt/pool/Music/
mv $HOME/Videos/* /mnt/pool/TV/

# Note I did not delete Documents, because we can use that folder as a 'container' for the 2 (or more) users sharing this workstation/desktop. 
# If you prefer you can delete Documents and replace it with a symbolic link to your user folder /Asterix/Documents.

# Now create several links, remember, the login account is actually Asterix in this example, so now we will link Asterix sub folders when available. 
# $HOME = a system variable and short for /home/asterix or whatever username you choose during OS installation. 
ln -s /mnt/pool/Music $HOME/
ln -s /mnt/pool/TV $HOME/
ln -s /mnt/pool/Users/$NAME1 $HOME/
ln -s /mnt/pool/Users/$NAME2 $HOME/
ln -s /mnt/pool/Users/$SHAREDUSER/Documents $HOME/
ln -s /mnt/pool/Users/$SHAREDUSER/Desktop $HOME/
ln -s /mnt/pool/Users/$SHAREDUSER/Downloads $HOME/
ln -s /mnt/pool/Users/$SHAREDUSER/Photos/ $HOME/

# Be warned, the file $HOME/.config/user-dirs.dirs contains the path of your account folders,
# if you rename folders (like I rename Pictures to Photos) or move folders (I prefer Templates (you can't get rid of it) to be within Documents) you need to change it here as well.
#
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
#
# Note, deleting or moving Desktop is not possible, the folder will be re-created immediately. 
# Temporarily change the location via a user config file, create the symlink, change it back. 
sudo sed -i -e 's+$HOME/Desktop+$HOME/Documents/Desktop+g' $HOME/.config/user-dirs.dirs
ln -s /mnt/pool/Users/Local/$SHAREDUSER/Desktop $HOME/
sudo sed -i -e 's+$HOME/Documents/Desktop+$HOME/Desktop+g' $HOME/.config/user-dirs.dirs

# after setting up NFS shares (see NFS v4.2 guide), you can mount the folders that are too large for the laptop/client devices:
# Other stuff like documents can be 2-way synced via Syncthing. 
#ln -s /mnt/servername/$SHAREDUSER/Photos $HOME/
