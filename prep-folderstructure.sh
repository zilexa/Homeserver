echo "Enter the name of the first workstation user (Monkey), followed by [ENTER]:"
read USERNAME1
echo USER1='"'$USERNAME1'"' >> /etc/environment
echo "Enter the name of the second workstation user (Fish), followed by [ENTER]:"
read USERNAME2
echo USER2='"'$USERNAME2'"' >> /etc/environment

# symlinks folder structure
ln -s /mnt/pool/Downloads /mnt/pool/Users/$USERNAME1/Homefolders/Downloads
ln -s /mnt/pool/Downloads /mnt/pool/Users/$USERNAME2/Homefolders/Downloads
ln -s /mnt/pool/Documents /mnt/pool/Users/$USERNAME1/Homefolders/Documents
ln -s /mnt/pool/Documents /mnt/pool/Users/$USERNAME2/Homefolders/Documents
ln -s /mnt/pool/Pictures /mnt/pool/Users/$USERNAME1/Homefolders/Pictures
ln -s /mnt/pool/Pictures /mnt/pool/Users/$USERNAME2/Homefolders/Pictures
ln -s /mnt/pool/Music /mnt/pool/Users/$USERNAME1/Homefolders/Music
ln -s /mnt/pool/Music /mnt/pool/Users/$USERNAME2/Homefolders/Music

# Replace home folder items for symlinks
TODO
