Chesterfield -- a Node.js CouchDB API-compatible HTTP server.

# Specifications and API

The API is REST/JSON as in CouchDB.

The Futon test suite is the specification.

Try to be close to CouchDB and BigCouch where it makes sense, but don't try to emulate undocumented quirks.

# Sharding, Load-balancing

Sharding/load-balancing is modular and configurable.

Provide REST-based, multi-layer scaling as map/reduce suggests it. (A final view result is a streamed merge of smaller view results.)

# Storage

Storage is modular and configurable.

Storage may be memory, disk, network, redis, memcached... as long as there
is a module to interface to it.

# Replication

Replication is an external process.

# Implementation

Re-use: express, request, ...

Ecosystem of sharding, storage, replication, ... modules.

# Thanks

daleharvey/pouchdb, mikeal/replicate

"Arthur looked. Much to his surprise, there was a velvet paisley-covered Chesterfield sofa in the field in front of them." Douglas Adams, *Life, the Universe, and Everything*
