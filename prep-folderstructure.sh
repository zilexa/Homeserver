# My folder structure might not be yours. 

echo "Enter the name of the first workstation user (example: Monkey), followed by [ENTER]:"
read NAME1
echo USER1='"'$NAME1'"' >> /etc/environment
echo "Enter the name of the second workstation user (example: Fish), followed by [ENTER]:"
read NAME2
echo USER2='"'$NAME2'"' >> /etc/environment

# symlinks folder structure, note the origin folders were created during MergerFS setup
ln -s /mnt/pool/Downloads /mnt/pool/Users/$NAME1/Homefolders/Downloads
ln -s /mnt/pool/Downloads /mnt/pool/Users/$NAME2/Homefolders/Downloads
ln -s /mnt/pool/Documents /mnt/pool/Users/$NAME1/Homefolders/Documents
ln -s /mnt/pool/Documents /mnt/pool/Users/$NAME2/Homefolders/Documents
ln -s /mnt/pool/Pictures /mnt/pool/Users/$NAME1/Homefolders/Pictures
ln -s /mnt/pool/Pictures /mnt/pool/Users/$NAME2/Homefolders/Pictures
ln -s /mnt/pool/Music /mnt/pool/Users/$NAME1/Homefolders/Music
ln -s /mnt/pool/Music /mnt/pool/Users/$NAME2/Homefolders/Music

# Replace home folder items for symlinks
rm -rf $HOME/Downloads
ln -s /mnt/pool/Downloads $HOME/Downloads
rm -rf $HOME/Documents
ln -s /mnt/pool/Documents $HOME/Documents
rm -rf $HOME/Pictures
ln -s /mnt/pool/Pictures $HOME/Pictures
rm -rf $HOME/Music
ln -s /mnt/pool/Music $HOME/Music
rm -rf $HOME/Media
ln -s /mnt/pool/Music $HOME/Music
