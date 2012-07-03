
# A local server with basic local storage
couchdb.createServer host, port,
  storage:
    couchdb.localStorage storage_dir
  replicator:
    couchdb.replicator()

# A server with sharding
couchdb.createServer host, port,
  storage:
    couchdb.shard list_of_shards
  replicator:
    couchdb.replicator()

