<?php
# Set your timezone
date_default_timezone_set("Europe/Amsterdam");
# ensure webDAV clients won't re-sync when the container is re-created (otherwise clients will delete all synced files and redownload them from server)
$config['system']['webdav']['skip_device_id_for_etag'] = true;
# every user has this folder containing their photos/pictures 
$config['app']['media']['photos']['library_root'] = '/Pictures';
# get your own url shortener, create a shorter subdomain, then register it at short.io and add this
$config['app']['weblinks']['custom_url_shortener'] = 'https://api.short.io/links/tweetbot?domain=YOUR-SHORT-DOMAIN-HERE&apiKey=YOUR-API-KEY-HERE&originalURL=###&urlOnly=1';
