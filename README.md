# MySQL-MariaDB-SimpleBackup

This script offers a straightforward solution for backing up all MySQL/MariaDB databases running locally on your system.
Tested on Ubuntu and Debian-based Linux Distros, it likely functions well on other distros too, provided mysqldump is installed.

It's designed for easy integration into a cron job or as a service.

## Installation as a daily cron job
```bash
sudo vi /etc/cron.daily/simpledb-backup
sudo run-parts /etc/cron.daily
```

By default, the script creates a local copy of the database before moving it to another folder—ideally, on a different physical storage medium. 
I implemented this process to address past issues with network shares becoming unavailable. Despite the hiccup, I deemed it prudent to retain a local backup on disk.
