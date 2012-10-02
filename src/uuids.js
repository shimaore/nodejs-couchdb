(function() {
  var crypto = require('crypto');

  var new_random_uuid = function(cb) {
    return crypto.randomBytes(16, function(e, buf) {
      if (e) {
        return cb(e);
      } else {
        return cb(null, buf.toString('hex'));
      }
    });
  };

  var new_sequential_uuid = function() {
    return crypto.randomBytes(13, function(e, buf) {
      var r;
      if (e) {
        return cb(e);
      } else {
        r = retrieve_database_uuid_sequence();
        return r.on('data', function(seq) {
          var seqbuf;
          seqbuf = new Buffer(4);
          seqbuf.writeUInt32BE(seq);
          seq += some_random_number;
          r = save_database_uuid_sequence(seq);
          r.on('error', function(e) {
            return cb(e);
          });
          return r.on('end', function() {
            var finalbuf;
            finalbuf = new Buffer(16);
            buf.copy(finalbuf, 0);
            seqbuf.copy(finalbuf, buf.length);
            return cb(null, finalbuf.toString('hex'));
          });
        });
      }
    });
  };

  var new_utc_uuid = function() {};

  var config = {
    retrieve: function(name,def) {
      return def;
    }
  };

  this.exports = function(cb) {
    switch (config.retrieve('uuids/algorithm', 'random')) {
      case 'sequential':
        return new_sequential_uuid(cb);
      case 'utc_random':
        return new_utc_uuid(cb);
      default:
        return new_random_uuid(cb);
    }
  };

}).call(module);
