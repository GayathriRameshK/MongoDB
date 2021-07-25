from pymongo import MongoClient
from time import sleep
from pymongo import ReadPreference
c = MongoClient('localhost', 27017)
config = {'_id': 'rs', 'members': [
     {'_id': 0, 'host': 'localhost:27017'},
     {'_id': 1, 'host': 'localhost:27018'},
     ]}


cl1 = MongoClient('localhost:27017', replicaset='rs')

print(cl1)

c = MongoClient(replicaset='rs');
print(c.nodes);
sleep(0.1);
print(c.nodes)

db = MongoClient("localhost", replicaSet='rs').test
db.test.insert_one({"x": 1}).inserted_id
res = db.test.find_one()
print(res)

cl_addr=db.client.address
print(cl_addr)

client = MongoClient(
     'localhost:27018',
     replicaSet='rs',
     readPreference='secondaryPreferred')
cl_read= client.read_preference
print(cl_read)

db = client.get_database('test', read_preference=ReadPreference.SECONDARY)
print(db.read_preference)
coll = db.get_collection('test', read_preference=ReadPreference.PRIMARY)
print( coll.read_preference)

coll2 = coll.with_options(read_preference=ReadPreference.NEAREST)
print(coll2.read_preference)

~
