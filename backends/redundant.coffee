
compare = (a,b) ->
  # Implement the CouchDB comparison algorithm
  #   compare(a,b) < 0  iff  a < b
  #   compare(a,b) = 0  iff  a = b
  #   compare(a,b) > 0  iff  a > b

class RedundantBackends

  # This backends records the same data in all its underlying backends.

  constructor: (@backends) ->

  # Strategies

  # @all:
  #   stop as soon as an error is reported
  #   successful iff all are successful
  #   return the last result received (assume all are identical)
  # supported events:
  #   `error`
  #   `end` (result)
  @all = (iterator) ->
    r = new EventEmitter
    completed = 0
    for backend in @backends
      do (backend) ->
        k = iterator backend
        k.once 'error', ->
          r.emit 'error'
        k.once 'end', (result) ->
          completed++
          if completed is @backends.length
            r.emit 'end', result
    r

  # @merge
  #   merge `data` events which occur with sorted values
  #   stop as soon as an error is reported
  #   successful iff all are successful
  # supported events:
  #   `error`
  #   `data` (data)
  #   'pause'
  #   'resume'
  #   `end`
  @merge = (iterator) ->
    r = new EventEmitter

    # Contain a {handler,queue} record for each backend
    # which has not already ended.
    handlers = []
    # If handlers[i].handler is null then backends[i] has `end`ed. No
    # new values will be received, but queued values may be present.
    # If handlers[i].handler is not null , but handler[i].queue is empty,
    # then backends[i] is in pending state, waiting for new values.

    handlers.min = ->
      min = null
      for h in handlers
        # Pending handler: need to wait for its next value to make a decision.
        if h.handler? and h.queue.length is 0
          return null
        # Keep the smallest one
        if h.queue.length > 0
          if compare(h.queue[0],min) <= 0
            min = h
      min

    # Attempt to send any remaining queued value.
    handlers.flush = ->
      # Clear anything we can in the queues.
      h = handler.min()
      if h?
        r.emit 'data', h.queue.shift()
        handlers.flush()
        return
      # Resume all pending handlers.
      for h in handlers when h.handler? and h.queue.length is 0
        h.handler.emit 'resume'

    handlers.all_done = ->
      for h in handlers
        if h.handler? or h.queue.length > 0
          return false
      true

    for backend, i in @backends
      do (backend,i) ->
        k = iterator backend
        h =
          handler: k
          queue: []
        handlers[i] = h

        k.once 'error', ->
          r.emit 'error'

        k.on 'data', (data) ->
          h.queue.push data
          k.emit 'pause'
          handlers.flush()

        k.once 'end', ->
          h.handler = null
          handlers.flush()
          if handlers.all_done()
            r.emit 'end'

    r.on 'pause', ->
      for k in handlers
        k.emit 'pause'
    r.on 'resume', ->
      handlers.flush()
    r

  # @any
  #   stop as soon as success is reported
  #   only one may provide data
  # supported events:
  #   `error`
  #   `end` (data)
  @any = (iterator) ->
    r = new EventEmitter
    completed = 0
    for backends in @backends
      do (backend) ->
        k = iterator backend
        k.once 'error', ->
          r.emit 'error'
        k.once 'end', (data) ->
          r.emit 'end', data
    r

  create_database: (name) ->
    @all (backend) ->
      backend.create_database name

  destroy_database: (name) ->
    @all (backend) ->
      backend.destroy_database name

  enumerate_databases: ->
    @merge (backend) ->
      backend.enumerate_databases cb

  retrieve_document: ->
    @any (backend) ->
      backend.retrieve_document

  update_document: (db, id, meta, body_buffer )->
    @all (backend) ->
      backend.update_document db, id, meta, body_buffer

  view: ->
    # stream-merge sorted results as they come from the different backends,
    # re-reduce if needed
