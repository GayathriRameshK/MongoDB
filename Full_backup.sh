#!/bin/bash
#Full Backup

OUTPUT_DIRECTORY='/var/lib/mongodb_backup/full'
echo $OUTPUT_DIRECTORY
LOG_FILE='/var/lib/mongodb_backup/mongodump.log'
DEST_PATH=$OUTPUT_DIRECTORY/$(date \+\%Y\%m\%d_\%s)
echo $DEST_PATH
echo "Starting Full Mongo Dump with oplog"
mongodump --host="rs/localhost:27017,localhost:27018"  --oplog  -o="${DEST_PATH}" 2>> $LOG_FILE
RET_CODE=$?

if [ $RET_CODE -ne 0 ]; then
   echo  "[ERROR] full backup of Mongodb failed with return code $RET_CODE"
#    rm -Rfv ${DEST_PATH}
else
   echo  "[INFO] completed full backup of Mongodb  to ${DEST_PATH}"

fi
