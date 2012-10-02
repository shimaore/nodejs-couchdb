(function() {
  var Couch = function Couch(opts) {
    if(!(this instanceof Couch)) {
      return new Couch(opts);
    }

    this.app = require('./api')(opts);
    return this;
  };

  Couch.Errors = {
    MISSING_DOC: {
      status: 404,
      error: 'not_found',
      reason: 'missing'
    },
    REV_CONFLICT: {
      status: 409,
      error: 'conflict',
      reason: 'Document update conflict'
    },
    INVALID_ID: {
      status: 400,
      error: 'invalid_id',
      reason: '_id field must contain a string'
    },
    UNKNOWN_ERROR: {
      status: 500,
      error: 'unknown_error',
      reason: 'Database encountered an unknown error'
    }
  };
  this.exports = Couch;
}).call(module);
