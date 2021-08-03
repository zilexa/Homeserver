#!/bin/bash
#
# Create customizables file with minimal customizations (do not touch if it already exists)
# -------------------------------------------------------------
## see here for more options: https://docs.filerun.com/advanced_configuration
cp -n postupdate/config.php customizables/


# OnlyOffice
# ----------
## Enable Autosave for OnlyOffice
sed -i -e 's|"autosave" => true|"autosave" => false|g' ./customizables/plugins/onlyoffice/app.php
## OnlyOffice - Set global default language & region
sed -i -e 's|"lang" => "en",|"lang" => "nl",\
				"location" => "nl",\
				"region" => "nl-NL",|g' ./customizables/plugins/onlyoffice/app.php


# Thumbnails & previews
# ---------------------
# Download, install pngquant and its dependencies
curl -o libimagequant.deb http://ftp.de.debian.org/debian/pool/main/libi/libimagequant/libimagequant0_2.12.2-1.1_amd64.deb
curl -o pngquant.deb http://ftp.de.debian.org/debian/pool/main/p/pngquant/pngquant_2.12.2-1_amd64.deb
apt install ./libimagequant.deb
apt install ./pngquant.deb
rm libimagequant.deb
rm pngquant.deb
# Download, build and install GraphicsMagick
curl -o GraphicsMagick.tar.xz -L https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/1.3.36/GraphicsMagick-1.3.36.tar.xz/download
tar -xf GraphicsMagick.tar.xz
cd GraphicsMagick*/
./configure
make install
cd ..
rm -rf GraphicsMagick*
# Download, extract, build and install AEScrypt
curl -o aescrypt.tgz https://www.aescrypt.com/download/v3/linux/aescrypt-3.14.tgz
tar -xf aescrypt.tgz
cd aescrypt*/src/
make
make install
cd .. && cd ..
rm -rf aescrypt*


# Enable favicons - Add icons and support for all browsers, homescreens and OS's. 
# -------------------------------------------------------------------------------
# Extract icons, get the assets from here: https://feedback.filerun.com/en/communities/1/topics/1196-a-new-favicon-for-filerun-with-support-for-all-devices-platforms-and-browsers
## Copy the downloaded file to your $HOME/docker/filerun/html/postupdate folder
tar -xf postupdate/favicon.tar.xz

# Replace a line with multiple lines to support all devices/OS's.
sed -i -e 's|<link rel="icon" type="image/x-icon" href="favicon.ico" />|<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">\
	<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">\
	<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">\
	<link rel="manifest" href="/site.webmanifest">\
	<link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5">|g' ./system/modules/fileman/sections/default/html/pages/index.html
sed -i -e 's|<link rel="icon" type="image/x-icon" href="favicon.ico" />|<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">\
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">\
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">\
<link rel="manifest" href="/site.webmanifest">\
<link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5">|g' ./system/modules/fileman/sections/default/html/pages/login.html


# BUGFIXES as released on feedback.filerun.com
# --------------------------------------------
# Thumbnails & previews not created: https://feedback.filerun.com/en/communities/1/topics/1216-thumbnail-problems
## Copy the downloaded file to your $HOME/docker/filerun/html/postupdate folder
cp -fr postupdate/ImageMagick.php system/classes/vendor/FileRun/Thumbs/Resizers/ImageMagick.php
