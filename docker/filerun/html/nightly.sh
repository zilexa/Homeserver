#!/bin/sh

# DO NOT RUN AS ROOT !!
# Running as root will create thumbnails owned by root. FileRun user will not be able to delete folders containing thumbnails.

# FileRun 
# -------
# Empty trash >30 days old files
/var/www/html/cron filerun php empty_trash.php -days 30
# Clear db of files/folders that no longer exist
/var/www/html/cron filerun php paths_cleanup.php --deep
# Index filenames for files created outside FileRun
/var/www/html/cron filerun php index_filenames.php /user-files true
# Read metadata of files created outside FileRun, the UI adjusts to photos (GPS), videos etc and has specific options per filetype
/var/www/html/cron filerun php metadata_index.php 
# Create thumbnails for files - allows instant scrolling through photos
/var/www/html/cron filerun php make_thumbs.php
# Create previews for files - allows instant previews for photos
/var/www/html/cron filerun php make_thumbs.php --username USERNAME1 --size large
/var/www/html/cron filerun php make_thumbs.php --username USERNAME2 --size large
/var/www/html/cron filerun php make_thumbs.php --username USERNAME3 --size large
/var/www/html/cron filerun php make_thumbs.php --username USERNAME4 --size large
/var/www/html/cron filerun php make_thumbs.php --username USERNAME5 --size large
/var/www/html/cron filerun php make_thumbs.php --username USERNAME6 --size large
# Index content of files, extracting text, to allow searching within files - not recommended
# usr/bin/docker exec -w /var/www/html/cron -it filerun php process_search_index_queue.php
