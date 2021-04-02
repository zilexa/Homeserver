#!/bin/sh
# These tasks should not require sudo, schedule via command: crontab -e

# Create a temp file to indicate maintenance is running
touch /tmp/maintenance-is-running


# CLEANUP WATCHED TVSHOWS & MOVIES
# --------------------------------
# delete if watched x days ago
$HOME/docker/HOST/jellyfin-cleaner/media_cleaner.py >> $HOME/docker/HOST/logs/media_cleaner.log

# CLEANUP CACHE
# -------------
# files >30d moved to data drives on pool-archive
/usr/bin/bash $HOME/docker/HOST/archiver.sh /mnt/disks/cache/Users /mnt/pool-nocache/Users 30

# FileRun 
# -------
# cleanup, thumbnail pre-caching, ElasticSearch file indexing
docker exec -w /var/www/html/cron -it filerun php empty_trash.php -days 30
docker exec -w /var/www/html/cron -it filerun php paths_cleanup.php
docker exec -w /var/www/html/cron -it filerun php metadata_index.php
docker exec -w /var/www/html/cron -it filerun php make_thumbs.php
docker exec -w /var/www/html/cron -it filerun php process_search_index_queue.php
docker exec -w /var/www/html/cron -it filerun php index_filenames.php true


# Delete temp file, follow up tasks can continue
rm /tmp/maintenance-is-running
