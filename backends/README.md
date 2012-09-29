Backends
========

There are multiple types of backends:
- plain storage backends: use some form of local storage (in-memory, on filesystem, in lvm..)
  - need to provide storage compartments
  - need to provide indexing techniques
  - need to proivde view etc computation & indexing
- local storage backends: use some form of local key:value storage (redis, memcached)
  - need to provide indexing techniques
  - need to provide view etc computation & indexing
- couchdb backends: these backends already provide all the needed features
  - e.g. remote couchdb
- multiplexing backends: these backends combine multiple backends to achieve
  - redundancy (identical data on all underlying backends)
  - load-balancing (e.g. via sharding)

As long as all backends have the same API they can be combined using any number of multiplexing backends; for example use a redundant multiplexing backend to save in memory using redis and on disk using the filesystem; or a load-balancing backend to build a front-end for large clusters, one of the shards being a multiplexing backend combining a local in-memory backend and a local filesystem backend.
