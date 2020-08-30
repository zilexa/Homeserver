# My folder structure might not be yours. 

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
