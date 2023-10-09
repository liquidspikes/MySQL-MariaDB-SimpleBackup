#!/bin/bash
# MariaDB database backup script
# Alex Zimmerman 2023-10-09

# Backup Location
Backup_Temp=/tmp/mariadb-backups-tmp
Backup_Destination=/mariadb-backups

# Number of days to keep archives
KEEP_DAYS=30

# Maximum number of backups to keep per database
MAX_BACKUPS=30

# Databases to exclude from individual backup
DB_EXCLUSIONS_LIST=(
    'information_schema'
    'performance_schema'
    'sys'
)

# Convert array to string for use later in the script
DB_EXCLUSIONS=$(IFS=,; echo "${DB_EXCLUSIONS_LIST[*]}")

# Script variables
Backup_Date=`date +%F`
Backup_Datetime=`date +%F-%H%M`

# Create backup folders if they don't exist
if [ ! -d "$Backup_Temp" ]; then
    mkdir -p "$Backup_Temp"
fi

if [ ! -d "$Backup_Destination" ]; then
    mkdir -p "$Backup_Destination"
fi

# Enable/Disable backup of all databases, please note this will include all system databases as well.
BACKUP_ALL_DATABASES=true

# PERFORM MariaDB DB backup and loops through each database, create a folder and backup file for each database.
echo 'Creating MariaDB DB archive files. Please wait ......'
for db in $(mysql -e "show databases;" -s --skip-column-names | grep -Ev "$DB_EXCLUSIONS"); do 
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
        # Move file to the final backup destination
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

# Backup all databases if enabled
if [ "$BACKUP_ALL_DATABASES" = true ]; then
    # Backup all databases
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
fi

# DELETE FILES OLDER THAN 30 days
echo 'Deleting backup older than '${KEEP_DAYS}' days'
find ${Backup_Destination} -type f -name "*.gz" -mtime +${KEEP_DAYS} -execdir rm -- {} \;
