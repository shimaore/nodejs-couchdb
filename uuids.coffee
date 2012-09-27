new_random_uuid = (cb) ->
  crypto.randomBytes 16, (e,buf) ->
    if e
      cb e
    else
      cb null, buf.toString 'hex'

new_sequential_uuid = ->
  crypto.randomBytes 13, (e,buf) ->
    if e
      cb e
    else
      r = retrieve_database_uuid_sequence()
      r.on 'data', (seq) ->
        seqbuf = new Buffer 4
        seqbuf.writeUInt32BE seq
        seq += some_random_number
        r = save_database_uuid_sequence seq
        r.on 'error', (e) ->
          cb e
        r.on 'end', ->
          finalbuf = new Buffer 16
          buf.copy finalbuf, 0
          seqbuf.copy finalbuf, buf.length
          cb null, finalbuf.toString 'hex'

new_utc_uuid = ->
  # TBD

module.exports = (cb) ->
    switch config.retrieve 'uuids/algorithm', 'random'
      when 'sequential'
        # 26 hex chars (13 bytes) random prefix, modified
        # when 6 characters (3 bytes) sequence (with random
        # increments)
        new_sequential_uuid cb
      when 'utc_random'
        # 14 hex microseconds since epoch, 18 hex random
        new_utc_uuid cb
      else # 'random'
        # 32 hex characters (16 bytes) at random
        new_random_uuid cb


