#!/bin/bash
# ZileXa: modified Maxwel's script to install fontforge (required for his script) and to include Segoeui and MS core fonts. 
# Author: Maxwel Leite
# Website: http://needforbits.wordpress.com/
# Description: Script to install Microsoft Vista TrueType Fonts (TTF) aka Microsoft’s ClearType fonts on Ubuntu distros
#              Microsoft added a group of new "ClearType Fonts" to Windows with Windows Vista and Office 2007.
#              These fonts are named Constantia, Corbel, Calibri, Cambria (and Cambria Math), Candara, and Consolas. 
#              Calibri became the default font on Microsoft Word 2007, and it’s still the default font on Word 2016 today.
# Dependencies: wget, fontforge and cabextract
# Note: Microsoft no longer provides the PowerPoint Viewer 2007 (v12.0.4518.1014) or any version anymore for download
# Tested: Ubuntu Saucy/Trusty/Xenial/Bionic/
# Added by ZileXa
sudo apt-get --yes --force-yes install fontforge
sudo apt-get --yes --force-yes install ttf-mscorefonts-installer
sudo mkdir -p /usr/share/fonts/truetype/msttcorefonts/
cd /usr/share/fonts/truetype/msttcorefonts/
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/segoeui.ttf?raw=true -O segoeui.ttf # regular
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/segoeuib.ttf?raw=true -O segoeuib.ttf # bold
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/segoeuib.ttf?raw=true -O segoeuii.ttf # italic
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/segoeuiz.ttf?raw=true -O segoeuiz.ttf # bold italic
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/segoeuil.ttf?raw=true -O segoeuil.ttf # light
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/seguili.ttf?raw=true -O seguili.ttf # light italic
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/segoeuisl.ttf?raw=true -O segoeuisl.ttf # semilight
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/seguisli.ttf?raw=true -O seguisli.ttf # semilight italic
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/seguisb.ttf?raw=true -O seguisb.ttf # semibold
sudo wget -q https://github.com/martinring/clide/blob/master/doc/fonts/seguisbi.ttf?raw=true -O seguisbi.ttf # semibold italic
fc-cache -f /usr/share/fonts/truetype/msttcorefonts/
# Original script starts here
output_dir="/usr/share/fonts/truetype/vista"
tmp_dir="/tmp/fonts-vista"

if [[ $EUID -ne 0 ]]; then
    echo -e "You must be a root user!\nTry: sudo ./ttf-vista-fonts-installer.sh" 2>&1
    exit 1
fi

if ! which wget >/dev/null; then
    echo "Error: wget is required to download the file"
    echo "Run the following command to install it:"
    echo "sudo apt-get install wget"
    exit 1
fi

if ! which cabextract >/dev/null; then
    echo "Error: cabextract is required to unpack the files"
    echo "Run the following command to install it:"
    echo "sudo apt-get install cabextract"
    exit 1
fi

if ! which fontforge >/dev/null; then
    echo "Error: fontforge is required to convert TTC files into TTF"
    echo "Run the following command to install it:"
    echo "sudo apt-get install fontforge"
    exit 1
fi

file="$tmp_dir/PowerPointViewer.exe"
mkdir -p "$tmp_dir"
cd "$tmp_dir"
err=0

echo -e "\n:: Downloading PowerPoint Viewer...\n"
wget -O "$file" https://web.archive.org/web/20171225132744/http://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
if [ $? -ne 0 ]; then
    rm -f "$file"
    echo -e "\nError: Download failed!?\n"
    err=1
else
    echo -e "Done!\n"
fi

if [ $err -ne 1 ]; then
    echo -n ":: Extracting... "
    cabextract -t "$file" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Can't extract. Corrupted download!?"
        err=1
    else
        cabextract -F ppviewer.cab "$file" &> /dev/null
        cabextract -L -F '*.tt?' ppviewer.cab &> /dev/null
        if [ $? -ne 0 ]; then
            echo "Error: Can't extract 'ppviewer.cab' from 'PowerPointViewer.exe'. Corrupted download!?"
            err=1
        else
            echo "Done!"
        fi
    fi
fi

if [ $err -ne 1 ]; then
# If you need the Cambria and Cambria Math (regular) font, you'll need to convert it to TTF because the font is available
# as a TrueType Collection (TTC) and unless you convert it, you won't be able to use it in LibreOffice for instance. 
    echo -n ":: Converting 'Cambria Regular' and 'Cambria Math Regular' (TTC - TrueType Collection) to TrueType (TTF)... "
    fontforge -lang=ff -c 'Open("cambria.ttc(Cambria)"); Generate("cambria.ttf"); Close(); Open("cambria.ttc(Cambria Math)"); Generate("cambriamath.ttf"); Close();' &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Can't convert file 'combria.ttc'."
        err=1
    else
        echo "Done!"
    fi
fi

if [ $err -ne 1 ]; then
    echo -n ":: Installing... "
    mkdir -p "$output_dir"
    cp -f "$tmp_dir"/*.ttf "$output_dir"  &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Can't copy files to output directory."
        err=1
    else
        echo "Done!"
    fi
fi

if [ $err -ne 1 ]; then
    echo -n ":: Clean the font cache... "
    fc-cache -f "$output_dir" &> /dev/null
    echo "Done!"
fi

echo -n ":: Cleanup... "
cd - &> /dev/null
rm -rf "$tmp_dir" &> /dev/null
echo "Done!"

if [ $err -ne 1 ]; then
    echo -e "\nCongratulations! Installation successful!!\n"
else
    echo -e "\nSome error occurred! Please try again!!\n"
fi
