async_map: (list,do_this) ->
  r = new EventEmitter
  n = list.length
  for x in list
    do_this x, (e) ->
      if e
        r.emit 'error', e
      else
        n--
        if n is 0
          r.emit 'end'
  r

class MultipleBackends

  constructor: (@backends) ->

  @map = (do_this) ->
    r = asyncmap @backends, (backend) ->
      do_this backend
      .on 'error', (e) -> r.error e
      .on 

  create_database: (name,cb) ->
    @map (backend) ->
      backend.create_database name

  destroy_database: (name,end) ->
    @map (backend) ->
      backend.destroy_database name, next
    .on 'end', end

  enumerate_databases: (each) ->
    @map (backend) ->
      backend.enumerate_databases cb

