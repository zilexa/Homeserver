
TBA


User schedule: 
`crontab -e`

```
MAILTO=""
30 2 * * * /usr/bin/bash /home/asterix/docker/HOST/maintenance.sh  >> /home/asterix/docker/HOST/logs/maintenance.log 2>&1
```
