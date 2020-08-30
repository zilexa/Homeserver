#!/bin/bash
#

echo "My folder structure might not be yours. 
echo "I use my Ubuntu Budgie server also as home PC/workstation, together with my partner (1 user account)."
echo "I want all local folders (Documents, Downloads, Desktop, Music, Pictures) to be stored on the drive Pool."
echo "To do that, I replace the folders in $HOME for symbolic links."
echo "I also want them to be accessible via the personal cloud accounts of each PC user."
echo "To do that, I create a /Home in each personal cloud folder of each PC user (/mnt/pool/Users/USERNAME/Home) with symbolic links to the folders."
echo ".."
echo "Enter the name of the first workstation user (example: Monkey), followed by [ENTER]:"
read NAME1
echo USER1='"'$NAME1'"' >> /etc/environment
echo "Enter the name of the second workstation user (example: Fish), followed by [ENTER]:"
read NAME2
echo USER2='"'$NAME2'"' >> /etc/environment

# Prepare replacing home folders for symlinks to the MergerFS Pool.
rm -rf $HOME/Downloads
rm -rf $HOME/Documents
rm -rf $HOME/Pictures
rm -rf $HOME/Music
rm -rf $HOME/Media

Use the MergerFS Pool to store the Home folders of this local PC, by creating symbolic links from Pool to $HOME. 
ln -s /mnt/pool/Local/Documents $HOME/
ln -s /mnt/pool/Local/Downloads $HOME/
ln -s /mnt/pool/Local/Music $HOME/
ln -s /mnt/pool/Local/Pictures $HOME/
ln -s /mnt/pool/Media $HOME/

Allow Home folders of this local PC to appear in cloud user folders for each PC user.
ln -s /mnt/pool/Local/Downloads /mnt/pool/Users/$NAME1/Home/
ln -s /mnt/pool/Local/Pictures /mnt/pool/Users/$NAME1/Home/
ln -s /mnt/pool/Local/Documents /mnt/pool/Users/$NAME1/Home/
ln -s /mnt/pool/Local/Music /mnt/pool/Users/$NAME1/Home/
ln -s /mnt/pool/Local/Desktop /mnt/pool/Users/$NAME1/Home/
ln -s /mnt/pool/Local/Desktop /mnt/pool/Users/$NAME2/Home/
ln -s /mnt/pool/Local/Music /mnt/pool/Users/$NAME2/Home/
ln -s /mnt/pool/Local/Documents /mnt/pool/Users/$NAME2/Home/
ln -s /mnt/pool/Local/Pictures /mnt/pool/Users/$NAME2/Home/
ln -s /mnt/pool/Local/Downloads /mnt/pool/Users/$NAME2/Home/
