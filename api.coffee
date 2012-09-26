
@include = ->

  # Trying to figure out the API
  # Is the list on
  #   http://wiki.apache.org/couchdb/Complete_HTTP_API_Reference
  # actually accurate and complete?

  # Actions maked 'system' are most probably implementation-dependent.
  # Review what BigCouch et al. do for these.
  

  #### Server-level misc. methods
  @get
    '/': ->
    '/favicon.ico': ->
    '_all_dbs': ->
    '/_active_tasks': -> # system
  @post
    '/_replicate'
  @all
    '/_replicator'  # replace with a normal database,
      # with an external replicator process monitoring its _changes
  @get
    '/_uuids'
  @post '/_restart' # system
  @get '/_stats'    # system
  @get '/_log'      # system
  @get '/_utils/*'  # replace with a normal database (if possible
    # based on paths) so that futon or futon2 may be used

  #### Server configuration
  @get '/_config'   # system?
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
  @all '/_users'

  #### Database methods
  # Note: restrict db names to proper syntax (what is it?)
  # (At least cannot start with underscore.)
  @get '/:db'
  @put '/:db'
  @del '/:db'
  @get '/:db/_changes'
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
  @post '/:db'
  @get  '/:db/:doc'
  @head '/:db/:doc'
  @put  '/:db/:doc'
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
