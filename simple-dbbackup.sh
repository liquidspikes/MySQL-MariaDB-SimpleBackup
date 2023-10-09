#!/bin/bash
# MariaDB / MySQL Simple database backup script
# Alex Zimmerman 2023-10-09

# Variables:

# Backup Locations
# Temporary location to backup on disk
Backup_Temp=/tmp/mariadb-backups-tmp
# Final backup location, could be a network mount or other non local location.
Backup_Destination=/mariadb-backups
# Number of days to keep archives
KEEP_DAYS=30
# Maximum number of backups to keep per database
MAX_BACKUPS=30
# Date Variables
Backup_Date=`date +%F`
Backup_Datetime=`date +%F-%H%M`

# Create backup folders if they don't exist
if [ ! -d "$Backup_Temp" ]; then
    mkdir -p "$Backup_Temp"
fi

if [ ! -d "$Backup_Destination" ]; then
    mkdir -p "$Backup_Destination"
fi

# PERFORM MariaDB DB backup
echo 'Creating MariaDB DB archive files. Please wait ......'
for db in $(mysql -e "show databases;" -s --skip-column-names | grep -Ev 'information_schema|performance_schema|sys'); do
    Backup_Folder=${Backup_Temp}/${db}
    mkdir -p ${Backup_Folder}
    Backup_FileName=${db}-${Backup_Datetime}.gz
    Backup_File=${Backup_Folder}/${Backup_FileName}
    echo "Backing up database ${db} to ${Backup_Destination}/${db}/${Backup_FileName}"
    mysqldump ${db} | gzip -9 > ${Backup_File}
    if [ $? -ne 0 ]; then
        echo "Error: Failed to backup database ${db}"
        exit 1
    fi
    # Move the backup file to the final backup destination, 
    # I did this just incase the final destination a network share, if the move fails at least you have one copy on disk still in your tmp.
    mkdir -p ${Backup_Destination}/${db}
    mv ${Backup_File} ${Backup_Destination}/${db}/${Backup_FileName}

    # Count number of backups for this database
    num_backups=$(ls -1 ${Backup_Destination}/${db}/*.gz | wc -l)

    # Delete old backups if there are more than MAX_BACKUPS
    if [ $num_backups -gt $MAX_BACKUPS ]; then
        echo "Deleting old backups for database ${db}"
        ls -1t ${Backup_Destination}/${db}/*.gz | tail -n +$MAX_BACKUPS | xargs rm --
    fi
done

# Backup all databases - This grabs everything, you might want to comment out this section as it can be large.
All_Databases_Folder=${Backup_Temp}/alldatabases
mkdir -p ${All_Databases_Folder}
All_Databases_FileName=all-databases-${Backup_Datetime}.gz
All_Databases_File=${All_Databases_Folder}/${All_Databases_FileName}
echo "Backing up all databases to ${Backup_Destination}/alldatabases/${All_Databases_FileName}"
mysqldump --all-databases | gzip -9 > ${All_Databases_File}
if [ $? -ne 0 ]; then
    echo "Error: Failed to backup all databases"
    exit 1
fi

# Move file to the final backup destination
mkdir -p ${Backup_Destination}/alldatabases
mv ${All_Databases_File} ${Backup_Destination}/alldatabases/${All_Databases_FileName}

# DELETE FILES OLDER THAN 30 days
echo 'Deleting backup older than '${KEEP_DAYS}' days'
find ${Backup_Destination} -type f -name "*.gz" -mtime +${KEEP_DAYS} -execdir rm -- {} \;
