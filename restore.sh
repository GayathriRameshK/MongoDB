restore.sh

#!/bin/bash -xe


FULL_DUMP_DIRECTORY='/var/lib/mongodb_backup/full/20210725_1627196380'
OPLOGS_DIRECTORY='/var/lib/mongodb_backup/oplogs'
OPLOG_LIMIT=1

FULL_DUMP_TIMESTAMP=`echo $FULL_DUMP_DIRECTORY | rev |  cut -d "/" -f 1 |rev |cut -d "_" -f 2`
LAST_OPLOG=""
ALREADY_APPLIED_OPLOG=0
#OPLOG=$OPLOGS_DIRECTORY/0000000000_0_oplog.bson.gz
#OPLOG_TIMESTAMP=`echo $OPLOG | rev | cut -d "/" -f 1 | rev | cut -d "_" -f 1`

mkdir -p /tmp/emptyDirForOpRestore

echo "restore full backup"
mongorestore  --host="rs1/localhost:27019,localhost:27020" $FULL_DUMP_DIRECTORY
echo "restore completed"
for OPLOG in `ls $OPLOGS_DIRECTORY/*.bson.gz`; do
   OPLOG_TIMESTAMP=`echo $OPLOG | rev | cut -d "/" -f 1 | rev | cut -d "_" -f 1`
   OPLOG_LIMIT= $OPLOG_TIMESTAMP:1
   if [ $OPLOG_TIMESTAMP -gt $FULL_DUMP_TIMESTAMP ]; then
      if [ $ALREADY_APPLIED_OPLOG -eq 0 ]; then
         ALREADY_APPLIED_OPLOG=1
         echo "applying oplog $LAST_OPLOG"
         mongorestore  --host="rs1/localhost:27019,localhost:27020" --oplogFile $LAST_OPLOG --oplogReplay --dir $OPLOGS_DIRECTORY --oplogLimit=$OPLOG_LIMIT
         echo "applying oplog $OPLOG"
         mongorestore --host="rs1/localhost:27019,localhost:27020" --oplogFile $OPLOG --oplogReplay --dir $OPLOGS_DIRECTORY --oplogLimit=$OPLOG_LIMIT
      else
         echo "applying oplog $OPLOG"
         mongorestore --host="rs1/localhost:27019,localhost:27020" --oplogFile $OPLOG --oplogReplay --dir $OPLOGS_DIRECTORY --oplogLimit=$OPLOG_LIMIT
      fi
   else
      LAST_OPLOG=$OPLOG
   fi
done

if [ $ALREADY_APPLIED_OPLOG -eq 0 ]; then
   if [ "$LAST_OPLOG" != "" ]; then
         echo "applying oplog $LAST_OPLOG"
         mongorestore --host="rs1/localhost:27019,localhost:27020" --oplogFile $LAST_OPLOG --oplogReplay --dir $OPLOGS_DIRECTORY --oplogLimit=$OPLOG_LIMIT
   fi
fi
