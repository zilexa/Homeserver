#!/bin/bash
# Permissions can be fixed as follows (this makes sure the personal folder cannot be deleted by the main user, but gives full access to the main user to the contents of the folder. 
# sudo chown asterix:asterix /mnt/pool/Users
# sudo chown asterix:asterix /mnt/pool/Music
# sudo chown asterix:asterix /mnt/pool/TV
# sudo chmod 775 -R /mnt/pool/Users
# sudo chmod 775 -R /mnt/pool/Music
# sudo chmod 775 -R /mnt/pool/TV
# note to self: figure out difference between 775 and u+rwx -R $NAME
echo "==========================================================================================================="
echo "If you are part of a family that has shared files, like Photo albums, Documents, files on Desktop, Downloads..." 
echo "they can be hard to incorporate in your folder structure." 
echo "Solve this by creating an extra user folder, besides the folders of you and your partner. Just call it Shared or come up with a funky name."
echo "This script will create the user folders for you, your partner and that made up user." 
echo "Next, it will create the common personal folders inside the made up user folder." 
echo "Then it will replace the common personal documents in your Home folder with links to this virtual user in your pool." 
echo "This virtual user folder can be seen as the shared folder, you can map it via Docker Compose (FileRun, see example in compose) to both of your user folders."
echo "You can even share tis virtual user folder over the LAN network via SMB or NFS." 
echo " "
echo "The benefit is that you maintain 1 single folder structure for all users, making backup organisation, filesystem organisation" 
echo "and local and online sharing just as easy as it is for all other users (1 method for all)." 
echo "==========================================================================================================="
read -p "Read between the lines then HIT CTRL+C to stop the script here or hit ENTER to start, you will be asked to enter names.. "
echo "==========================================================================================================="
echo "Enter your name followed by ENTER. First letter capital, this will be /mnt/pool/Users/Yourname and a symlink will be added to your home/user/ folder:"
read -p "Enter your name: " NAME1
echo "you entered $NAME1"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Now enter the name of your partner or other person that can use this workstation, same actions will be performed:"
read -p "Enter your fam member name: " NAME2
echo "you entered $NAME2"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Now come up with a name for the shared user folder, for example Batman." 
echo "This workstation common personal folders (Desktop, Documents etc) will be moved to the pool and symlinked back to the home/user/ folder:"
read -p "Enter a name: " SHAREDUSER
echo "you entered $SHAREDUSER"
read -p "if you are satisfied, hit a key to continue or CTRL+C to abort, no changes to your system have been made."

# This folder will contain files of all users. Each folder is the private cloud of each user. These folders can be synced and/or easily accessed via apps. 
# Collections can be made available as subdirs within each User folder, via symlink (we will get there). 
mkdir -p /mnt/pool/Users/$NAME1
mkdir -p /mnt/pool/Users/$NAME2
mkdir -p /mnt/pool/Users/$SHAREDUSER


mkdir -p /mnt/pool/Users/$SHAREDUSER/{Documents,Photos,Desktop,Downloads}


# If you plan to download series/movies, create a seperate folder structure for it as the material is not unique and not bound to a user and does not require extensive backups. 
# Note the subdirs have been specifically chosen this way to work perfectly with common download tools. Recommend to stick to it exactly.
mkdir -p /mnt/pool/Music
mkdir -p /mnt/pool/TV/{Series,Movies,incoming}
mkdir -p /mnt/pool/TV/incoming/{complete,blackhole}

# To prevent defragmentation due to downloading, make sure your download client downloads to this incomplete dir.
# By creating a subvolume for it now, when a file is finished downloading, it will be copied as a whole into the complete dir, because it's coming from a different subvol.
# Although this is more intensive then simply changing the location, since the file needs to be copied, it will massively reduce fragmentation and also disk I/O when
# reading (especially during seeding!) that file. Sonarr can still hardlink from the complete dir to the actual Movies or Series dir. 
# Especially for btrfs, this is highly recommended!
btrfs subvolume create /mnt/disks/cache/TV/incoming/incomplete
btrfs subvolume create /mnt/disks/data1/TV/incoming/incomplete
btrfs subvolume create /mnt/disks/data2/TV/incoming/incomplete
btrfs subvolume create /mnt/disks/data3/TV/incoming/incomplete
# Disable copy-on-write for this dir (otherwise it will constantly rewrite the whole file during downloading) on all disks and the pool: 
chattr -R +C /mnt/disks/cache/TV/incoming/incomplete
chattr -R +C /mnt/disks/data1/TV/incoming/incomplete
chattr -R +C /mnt/disks/data2/TV/incoming/incomplete
chattr -R +C /mnt/disks/data3/TV/incoming/incomplete
chattr -R +C /mnt/pool/TV/incoming/incomplete

# (optional) if you plan to use this server as workstation/desktop, you will use the Home/Username/ personal folders. 
# This means you need to map the fictious/shared users' personal folders to the OS $HOME directory.. That's easy and pretty common on Linux: replace the folders for symbolic links.
# In case you already have data in those folders, move it to the pool: 
mv $HOME/Documents/* /mnt/pool/Users/$SHAREDUSER/Documents/
mv $HOME/Desktop/* /mnt/pool/Users/$SHAREDUSER/Desktop/
mv $HOME/Downloads/* /mnt/pool/Users/$SHAREDUSER/Downloads/
mv $HOME/Pictures/* /mnt/pool/Users/$SHAREDUSER/Photos/
mv $HOME/Music/* /mnt/pool/Music/
mv $HOME/Videos/* /mnt/pool/TV/

# Note I did not delete Documents, because we can use that folder as a 'container' for the 2 (or more) users sharing this workstation/desktop. 
# If you prefer you can delete Documents and replace it with a symbolic link to your user folder /shareduser/Documents.

# Now create several links, remember, the login account is actually shareduser in this example, so now we will link shareduser sub folders when available. 
# $HOME = a system variable and short for /home/shareduser or whatever username you choose during OS installation. 
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
