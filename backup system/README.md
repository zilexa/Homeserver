TBA
---

User schedule: 
`crontab -e`

```
MAILTO=""
0 2 * * * /usr/bin/bash /home/asterix/docker/HOST/maintenance.sh  >> /home/asterix/docker/HOST/logs/maintenance.log 2>&1
```

Root schedule: 
`sudo crontab -e`

```
MAILTO=""
30 2 * * * /usr/bin/bash /home/asterix/docker/HOST/backup.sh >> /home/asterix/docker/HOST/logs/backup.log 2>&1
```

