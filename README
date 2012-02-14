A CouchDB implementation in Node.js

# Specifications and API

The API is REST/JSON as in CouchDB.

Futon (especially the Futon test suite) is the specification.

Try to be close to CouchDB and BigCouch where it makes sense, but don't try to emulate unspecified quirks.

# Sharding

Sharding is modular and configurable.

Plain CouchDB operates with sharding "none".

Provide REST-based, multi-layer scaling as map/reduce suggests it. (A final view result is a streamed merge of smaller view results.)

# Storage

Storage is modular and configurable.

Storage may be memory, disk, network, redis, memcached... as long as there
is a module to interface to it.

Base (local disk) storage which offers at least the same properties as
CouchDB's original storage is provided by default.

# Replication

Replication is an external process.

(...since a priori CouchDB offers all the public interfaces (_changes and _local) to write a third-party replicator outside of the core.)

# Implementation

JavaScript and/or CoffeeScript.

Re-use: express, request, nano..

Ecosystem of sharding, storage, replication, ... modules.
