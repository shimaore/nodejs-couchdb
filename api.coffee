@include = ->

  # backend API:
  #   create_database name            # error, end
  #   destroy_database name           # error, end
  #   enumerate_databases             # 'data' (name), error, pause, resume, end
  #   retrieve_document db, doc_id    # error, end (doc)
  #   update_document, db, doc_id, meta, body_buffer  # error, end
  # Events:
  #   # error occurred (final)
  #   'error', (error) ->
  #   # successful completion (final)
  #   'end'
  #   # one more to retrieve data
  #   'data'

  backend

  motd = 'Welcome'

  # Trying to figure out the API
  # Is the list on
  #   http://wiki.apache.org/couchdb/Complete_HTTP_API_Reference
  # actually accurate and complete?

  helper
    start_json: ->
      headers =
        'Content-Type': 'application/json'
        'Cache-Control': 'must-revalidate'
      @res.writeHead 200, headers

  # Actions maked 'system' are most probably implementation-dependent.
  # Review what BigCouch et al. do for these.

    push_revision: (meta,body) ->
      meta.rev = body._rev = meta.version + '-' + new_uuid()
      body_as_json = JSON.stringify body
      body_buffer = new Buffer body_as_json
      meta.etag = md5sum_as_hex body_buffer
      meta.length = body_buffer.length
      r1 = backend.next_database_update_seq()
      r1.on 'error', ->
        @res.writeHead 500
      r1.on 'data', (seq) ->
        meta.local_seq = seq
        r2 = backend.update_document @params.db, @params.doc, meta, body_as_json
        r2.on 'error', (e) ->
          @res.writeHead 500
        r2.on 'end', ->
          @json ok:true

#### Server-level misc. methods
  @get '/', ->
      # http://wiki.apache.org/couchdb/HttpGetRoot
      # Note: Apache CouchDB sends text/plain, not json
      @json
        couchdb: motd
        version: '0.1.0'

  # @get '/favicon.ico': ->
  @use 'favicon'

  @get '/_all_dbs', ->
      # http://wiki.apache.org/couchdb/HttpGetAllDbs
      # Note: Apache CouchDB sends text/plain, not json
      # Note: this could be a very long list. I originally planned
      # to make this async, but Apache CouchDB provides a Content-Length
      # for it?? (And their list is sorted??)
      all_dbs = []
      r = backend.enumerate_databases()
      r.on 'data', (name) ->
        all_dbs.push name
      r.on 'error', (e) ->
        @res.writeHead 500
        @res.end
      r.on 'end', (e) ->
        @json all_dbs

  @get '/_active_tasks', -> # system
    @res.writeHead 500
  @post '/_replicate', ->
    @res.writeHead 500 # re-use mikeal/replicate here

  # @all '/_replicator', ->
  #   replace with a normal database,
  #   with an external replicator process monitoring its _changes

  backend.create_database '_replicator'
  monitor_database '_replicator', (change) ->
    # start/stop a given replication
  start_replicators()

  couch_uuid = require './uuids'

  # http://wiki.apache.org/couchdb/HttpGetUuids
  @get '/_uuids', ->
    count = @query.count ? 1
    uuids = []
    r = couch_uuid() (e,value) ->
        if e
          @res.writeHead 500
        else
          uuids.push value
          if i is count
            @json uuid: uuids
          else
            r()

  @post '/_restart' # system
  @get '/_stats'    # system
  @get '/_log'      # system
  # @get '/_utils/*'
  #   replace with a normal database (if possible
  #   based on paths) so that futon or futon2 may be used

  # Note: we make _utils a couchapp, à la futon2
  ensure_database '_utils'
  push_app '_utils'

  #### Server configuration
  # system?
  @get '/_config'
  @get '/_config/:section'
  @get '/_config/:section/:key'
  @put '/_config/:section/:key'
  @del '/_config/:section/:key'

  #### Authentication
  # Related note: authentication at query time is done by a specific
  # middleware, which requests auth based on configuration and path
  # (e.g. /_utils should probably be public and never request auth).
  @get '/_session'
  @post '/_session'
  @del '/_session'
  # I'll probably let someone more clever than me implement those..
  @get '/_oauth/access_token'
  @get '/_oauth/authorize'
  @post '/_oauth/authorize'
  @all '/_oauth/request_token'

  #### User database
  # This is a regular database
  # @all '/_users'
  ensure_database '_users'
  push_app '_users'

  #### Database methods
  # Note: restrict db names to proper syntax (what is it?)
  # (At least cannot start with underscore.)
  @get '/:db', ->
    @json
      name: @params.db

  @put '/:db', ->
    r = backend.create_database @params.db
    r.on 'error', (e) ->
      @res.writeHead 412
    r.on 'end', (data) ->
      @json ok:true

  @del '/:db', ->
    r = backend.destroy_database @params.db
    r.on 'error', (e) ->
      @res.writeHead 404
    r.on 'end', ->
      @json ok:true

  @get '/:db/_changes', ->

  @post '/:db/_compact' # system
  @post '/:db/_compact/:design' # system
  @post '/:db/_view_cleanup' # system
  @post '/:db/_temp_view' # I think BigCouch did away with those
  @post '/:db/_ensure_full_commit'
  @post '/:db/_bulk_docs'
  @post '/:db/_purge'
  @get '/:db/_all_docs' # It'd be really nice to make it behave like real views though
  @post '/:db/_all_docs'
  @post '/:db/_missing_revs'
  @post '/:db/_revs_diff'
  @get '/:db/_security'
  @put '/:db/_security'
  @get '/:db/_revs_limit'
  @put '/:db/_revs_limit'

  #### Database document methods
  # Note: resttrict doc names to valid ones (what are they?)
  # At least, cannot start with underscore.
  @post '/:db', ->

  @get  '/:db/:doc', ->
    r = backend.retrieve_document @params.db, @params.doc
    r.on 'data', (doc) ->
      @json doc
    r.on 'error', (e) ->
      @res.writeHead 404

  @head '/:db/:doc', ->

  @put  '/:db/:doc', ->
    r = backend.retrieve_document_meta @params.db, @params.doc
    r.on 'data', (meta) ->
      # Check revision
      if @body._rev isnt meta.rev
        @res.writeHead 409
        return
      # Check ID is consistent
      if @body._id isnt meta.id
        @res.writeHead 400
        return
      # Create new meta
      new_meta = 
        id: meta.id
        version: meta.version+1
      @push_revision new_meta, @body

    r.on 'error', ->
      # New document
      if @body._rev?
        @res.writeHead 400
        return
      # Check ID is consistent
      if @body._id isnt meta.id
        @res.writeHead 400
        return
      # Create new meta
      new_meta =
        id: meta.id
        version: 1
      push_revision new_meta, @body

  @del  '/:db/:doc'
  @copy '/:db/:doc'
  #### Attachments
  @get  '/:db/:doc/*'
  @put  '/:db/:doc/*'
  @del  '/:db/:doc/*'
  #### Non-replicating documents
  @get  '/:db/_local/:doc'
  @put  '/:db/_local/:doc'
  @del  '/:db/_local/:doc'
  @copy '/:db/_local/:doc'
  #### Design documents
  @get  '/:db/_design/:design'
  @put  '/:db/_design/:design'
  @del  '/:db/_design/:design'
  @copy '/:db/_design/:design'
  #### Design documents attachments
  # Note: attachment name cannot start with underscore
  @get  '/:db/_design/:design/*'
  @put  '/:db/_design/:design/*'
  @del  '/:db/_design/:design/*'

  #### Special design document handlers
  # Info
  @get  '/:db/_design/:design/_info'
  # Views
  @get  '/:db/_design/:design/_view/:view'
  @post '/:db/_design/:design/_view/:view'
  # Shows
  @get  '/:db/_design/:design/_show/:show'
  @get  '/:db/_design/:design/_show/:show/*'
  # Lists
  @get  '/:db/_design/:design/_list/:list/:view'
  @post '/:db/_design/:design/_list/:list/:view'
  @get  '/:db/_design/:design/_list/:list/:other_design/:view'
  @post '/:db/_design/:design/_list/:list/:other_design/:view'
  # Update
  @put  '/:db/_design/:design/_update/:update'
  @post '/:db/_design/:design/_update/:update'
  @put  '/:db/_design/:design/_update/:update/:doc'
  @post '/:db/_design/:design/_update/:update/:doc'
  # Rewrite
  @all  '/:db/_design/:design/_rewrite/:rewrite/*'

  # Is that it?
