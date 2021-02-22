TBA
---

Root schedule: 
`sudo crontab -e`

```
MAILTO=""
0 3 * * * /usr/bin/bash /home/asterix/docker/HOST/backup.sh >> /home/asterix/docker/HOST/logs/backup.log 2>&1
```

