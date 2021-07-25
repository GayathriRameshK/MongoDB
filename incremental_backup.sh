incrementalbackup.sh

#!/bin/bash

OUTPUT_DIRECTORY='/var/lib/mongodb_backup'
echo "[INFO] starting incremental backup of oplog"

mkdir -p -v $OUTPUT_DIRECTORY/oplogs
LOG_FILE='/var/lib/mongodb_backup/oplogs/mongo_oplog.log'

LAST_OPLOG_DUMP=`ls -t ${OUTPUT_DIRECTORY}/oplogs/*.bson.gz  2> /dev/null | head -1`

if [ "$LAST_OPLOG_DUMP" != "" ]; then
   echo "[DEBUG] last incremental oplog backup is $LAST_OPLOG_DUMP"
   set -o xtrace
   LAST_OPLOG_ENTRY=`zcat ${LAST_OPLOG_DUMP} | bsondump 2>> $LOG_FILE | grep ts | tail -1`
   set +o xtrace
   if [ "$LAST_OPLOG_ENTRY" == "" ]; then
     echo "[ERROR] evaluating last backed-up oplog entry with bsondump failed"
      exit 1
   else
      TIMESTAMP_LAST_OPLOG_ENTRY=`echo $LAST_OPLOG_ENTRY | jq '.ts[].t'`
      INC_NUMBER_LAST_OPLOG_ENTRY=`echo $LAST_OPLOG_ENTRY | jq '.ts[].i'`
      START_TIMESTAMP="{\"\$timestamp\":{\"t\":${TIMESTAMP_LAST_OPLOG_ENTRY},\"i\":${INC_NUMBER_LAST_OPLOG_ENTRY}}}"
     echo "[DEBUG] dumping everything newer than $START_TIMESTAMP"
   fi
   echo "[DEBUG] last backed-up oplog entry: $LAST_OPLOG_ENTRY"
else
   echo "[WARN] no backed-up oplog available. creating initial backup"
   TIMESTAMP_LAST_OPLOG_ENTRY=0000000000
   INC_NUMBER_LAST_OPLOG_ENTRY=0
fi

OPLOG_OUTFILE=${OUTPUT_DIRECTORY}/oplogs/${TIMESTAMP_LAST_OPLOG_ENTRY}_${INC_NUMBER_LAST_OPLOG_ENTRY}_oplog.bson.gz

if [ "$LAST_OPLOG_ENTRY" != "" ]; then
   OPLOG_QUERY="{ \"ts\" : { \"\$gt\" : $START_TIMESTAMP } }"
   set -o xtrace
   mongodump --host="rs/localhost:27017,localhost:27018" -c oplog.rs --query "${OPLOG_QUERY}"  > $OPLOG_OUTFILE 2>> $LOG_FILE
   set +o xtrace
   RET_CODE=$?
else 
   set -o xtrace
   mongodump --host="rs/localhost:27017,localhost:27018" -c oplog.rs > $OPLOG_OUTFILE 2>> $LOG_FILE
   set +o xtrace
   RET_CODE=$?
fi

if [ $RET_CODE -gt 0 ]; then
   echo "[ERROR] incremental backup of oplog with mongodump failed with return code $RET_CODE"
fi

FILESIZE=`stat --printf="%s" ${OPLOG_OUTFILE}`

# Note that I found many times when I had a failure I still had a 20 byte file;
# I figured anything smaller than 50 bytes isn't big enough to matter regardless
if [ $FILESIZE -lt 50 ]; then
   echo "[WARN] no documents have been dumped with incremental backup (no changes in mongodb since last backup?). Deleting ${OPLOG_OUTFILE}"
   rm -f ${OPLOG_OUTFILE}
else
  echo "[INFO] finished incremental backup of oplog to ${OPLOG_OUTFILE}"
fi