#!/bin/bash
# Script to backup a MongoDB machine from a remote server
# This script allows for retention parameters, global or database/collection specific backups

# Log this script output to a file
exec > ${SCRIPTPATH}/log/mongo_backup.log 2>&1

###########################
####### LOAD CONFIG #######
###########################
while [ $# -gt 0 ]; do
        case $1 in
                -c)
                        CONFIG_FILE_PATH="$2"
                        shift 2
                        ;;
                *)
                        ${ECHO} "Unknown Option \"$1\"" 1>&2
                        exit 2
                        ;;
        esac
done

if [ -z $CONFIG_FILE_PATH ] ; then
        SCRIPTPATH=$(cd ${0%/*} && pwd -P)
        CONFIG_FILE_PATH="${SCRIPTPATH}/mongo_backup.config"
fi

if [ ! -r ${CONFIG_FILE_PATH} ] ; then
        echo "Could not load config file from ${CONFIG_FILE_PATH}. Exiting." 1>&2
        exit 1
fi

source "${CONFIG_FILE_PATH}"

###########################
#### PRE-BACKUP CHECKS ####
###########################
# Verify that this script is running as the specified user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ] ; then
	echo "This script must be run as $BACKUP_USER. Exiting." 1>&2
	exit 1
fi

if [ ! $PG_PASS ]; then
    echo "Make sure the user password for $USERNAME is provided in the configuration file. Exiting." 1>&2
    exit 1
fi

###########################
### INITIALISE DEFAULTS ###
###########################
# As MongoDB has no enabled access control by default, assume the use of empty values
# in the case that the configured variables are empty
if [ ! $HOSTNAME ]; then
	HOSTNAME=""
fi;

if [ ! $USERNAME ]; then
	USERNAME=""
fi;


###########################
#### START THE BACKUPS ####
###########################
function perform_backups()
{
	SUFFIX=$1
	FINAL_BACKUP_DIR=$BACKUP_DIR"`date +\%Y-\%m-\%d`$SUFFIX/"

	echo "Making the backup directory in $FINAL_BACKUP_DIR"

	if ! mkdir -p $FINAL_BACKUP_DIR; then
		echo "Cannot create backup directory in $FINAL_BACKUP_DIR. Go and fix it!" 1>&2
		exit 1;
	fi;
	
	###########################
	###### FULL BACKUPS #######
	###########################
	echo -e "\n\nPerforming full database backups"
	echo -e "--------------------------------------------\n"

		echo "Plain backup of $DATABASE"
	 
		set -o pipefail
		mongodump --uri="$URI" --out="$FINAL_BACKUP_DIR" --gzip --oplog
		set +o pipefail

	echo -e "\nAll database backups complete!"
}

# MONTHLY BACKUPS
DAY_OF_MONTH=`date +%d`

if [ $DAY_OF_MONTH -eq 1 ];
then
	# Delete all expired monthly directories
	find $BACKUP_DIR -maxdepth 1 -name "*-monthly" -exec rm -rf '{}' ';'
	        	
	perform_backups "-monthly"
	
	exit 0;
fi

# WEEKLY BACKUPS
DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
EXPIRED_DAYS=`expr $((($WEEKS_TO_KEEP * 7) + 1))`

if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ];
then
	# Delete all expired weekly directories
	find $BACKUP_DIR -maxdepth 1 -mtime +$EXPIRED_DAYS -name "*-weekly" -exec rm -rf '{}' ';'
	        	
	perform_backups "-weekly"
	
	exit 0;
fi

# DAILY BACKUPS
# Delete daily of 7 days or more
find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*-daily" -exec rm -rf '{}' ';'

perform_backups "-daily"
