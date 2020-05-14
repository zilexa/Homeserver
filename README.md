# Mediaserver
Docker based server:
Ubuntu PC running Ubuntu Budgie and the following services via Docker Compose:

PiHole running via macvlan (required). Accessable via the host itself, normally this is not possible and not an issue when you run it on a standalone NAS (Raspberry Pi or Synology). 

Correct folder structure and Docker setup for torrents:
https://old.reddit.com/r/usenet/wiki/docker#wiki_consistent_and_well_planned_paths


wip:
Assumes you have 2 disks for data, 1 for parity
Assumes you will use the system SSD also as cache
echo Assumes you will create 2 pools, 1 with only the HDDs "ARCHIVE", one with HDDs + a folder on SSD "POOL"  . 
echo 2 overlapping pools are required for caching, see MergerFS readme. 
echo By default data is written to POOL, which allows writing to SSD if plenty of free space otherwise to disks. 
echo Via a scheduled script, data from POOL/cache will be moved to ARCHIVE to keep SSD clean. 
