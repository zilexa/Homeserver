#!/bin/sh
# FileRun maintenance tasks - warning: should be run as the Filerun user (Apache user), as configured in Docker Compose! Usually this is the user of your system, running Docker. Never root! Otherwise you will have permissions issues and will not be able to delete folders containing thumbnails. 
# -------
# Empty trash >30 days old files
docker exec -w /var/www/html/cron filerun php empty_trash.php -days 30
# Clear db of files/folders that no longer exist
docker exec -w /var/www/html/cron filerun php paths_cleanup.php --deep --agressive -remove-hidden
# Index filenames for files created outside FileRun
docker exec -w /var/www/html/cron filerun php index_filenames.php /user-files true
# Read metadata of files created outside FileRun, the UI adjusts to photos (GPS), videos etc and has specific options per filetype
docker exec -w /var/www/html/cron filerun php metadata_index.php 
# Create thumbnails for files - allows instant scrolling through photos
docker exec -w /var/www/html/cron filerun php make_thumbs.php
# Create previews for files - allows instant previews for photos
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username rudhra --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username asterix --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username shanti --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username mahesh --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username shanta --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username madhuri --size large
docker exec -w /var/www/html/cron filerun php make_thumbs.php --username divya --size large
# Index content of files, extracting text, to allow searching within files - not recommended
# usr/bin/docker exec -w /var/www/html/cron -it filerun php process_search_index_queue.php
