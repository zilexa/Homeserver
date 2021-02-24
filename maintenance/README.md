
TBA


User schedule: 
`crontab -e`

```
# Disable errors appearing in syslog
MAILTO=""
# Nightly at 02.30h run maintenance (tv cleanup, cache archiver, snapraid-btrfs, snapraid-btrfs cleanup)
30 2 * * * /usr/bin/bash /home/asterix/docker/HOST/maintenance.sh | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> /home/asterix/docker/HOST/logs/maintenance.log 2>&1
#
# Every 6hrs between 10.00-23.00 run snapraid-btrfs
0 10-23/6 * * * snapraid-btrfs sync | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> $HOME/docker/HOST/logs/snapraid-btrfs.log 2>&1
```
