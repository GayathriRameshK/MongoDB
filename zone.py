print('Hello, world!')

import pymongo
import pprint

mongo_uri = "mongodb://127.0.0.1:27019/"
client = pymongo.MongoClient(mongo_uri)
cl=client.list_database_names()
print(cl)

db=client.admin
#db1=db.getSiblingDB("admin")
chk=db.command("balancerStatus")
print(chk)
print(chk['mode'])
print(chk['inBalancerRound'])
bal_mod=chk['mode']
bal_round=chk['inBalancerRound']
print(bal_mod)
print(bal_mod == 'off')
if(bal_mod == 'full'):
    try:
        db.command("balancerStop")
        print("Step1: Disable Balancer success")
    except Exception as e:
        print(e)
        print("Step1 Disable Balancer failed")
elif(bal_mod == 'off'):
     print('out')
     print('Good to proceed')
     try:
         db.command({"addShardToZone": "srs1" , "zone": "recent"})
         db.command({"addShardToZone": "srs2" , "zone": "recent"})
         db.command({"addShardToZone": "srs3" , "zone": "archive"})
         db.command({"addShardToZone": "srs4" , "zone": "archive"})
         db.command({"addShardToZone": "srs5" , "zone": "archive"})
         print('Zone Added')
        
     except Exception as e:
         print(e)
         print("Add Shard Tag failed")
     try:
         db.command(
         {
         "updateZoneKeyRange" : "persons.datanew",
         "min" : { "personid" : 10001},
         "max" : { "personid" : 10010},
         "zone" : "recent"
         }
         )
         print("recent zone updated")

         db.command(
         {
         "updateZoneKeyRange" : "persons.datanew",
         "min" : { "personid" : 20001},
         "max" : { "personid" : 50010},
         "zone" : "archive"
         }
         )
         print("archive zone updated")

     except Exception as e:
         print(e)
         print("Add Shard Tag Range failed")

try:
   db.command("balancerStart")
   print("Enable Balancer success")		 
   db.command('enableSharding', 'persons')
   db.command('shardCollection', 'persons.datanew', key={'personid': 1})
except Exception as e:
         print(e)
         print("Enable Sharding Failed")

