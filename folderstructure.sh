echo "Enter the name of the first workstation user (Monkey), followed by [ENTER]:"
read USERNAME1
echo USER1='"'$USERNAME1'"' >> /etc/environment
echo "Enter the name of the second workstation user (Fish), followed by [ENTER]:"
read USERNAME2
echo USER2='"'$USERNAME2'"' >> /etc/environment

# symlinks folder structure
ln -s /mnt/pool/Downloads /mnt/pool/Users/Rudhra/Homefolders/Downloads
ln -s /mnt/pool/Downloads /mnt/pool/Users/Shanti/Homefolders/Downloads
ln -s /mnt/pool/Documents /mnt/pool/Users/Rudhra/Homefolders/Documents
ln -s /mnt/pool/Documents /mnt/pool/Users/Shanti/Homefolders/Documents
ln -s /mnt/pool/Pictures /mnt/pool/Users/Rudhra/Homefolders/Pictures
ln -s /mnt/pool/Pictures /mnt/pool/Users/Shanti/Homefolders/Pictures
ln -s /mnt/pool/Music /mnt/pool/Users/Rudhra/Homefolders/Music
ln -s /mnt/pool/Music /mnt/pool/Users/Shanti/Homefolders/Music

# Replace home folder items for symlinks
TODO
