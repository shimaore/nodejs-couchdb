/*
 * A dummy (development) backend for Chesterfield.
 *
 * This uses one file per database, all data is read (sync) and written (sync) to do a simple update,
 * no locking, can't handle parallel queries, etc.
 */

var DummyBackend = (function() {

  var fs = require('fs');
  var path = require('path');
  var EventEmitter = require('events').EventEmitter;
  var Couch = require('../src/couch');

  function DummyBackend(base) {
    this.base = base;
  };

  DummyBackend.prototype.path = function(name) {
    return path.join(this.base,name+'.couch.json');
  };

  DummyBackend.prototype.create_database = function(name,cb) {
    var content = JSON.stringify({meta:{},docs:{}});
    fs.writeFile(this.path(name),content,function(error) {
      if(error) {
        console.dir(error);
        cb(Couch.Errors.UNKNOWN_ERROR);
      } else {
        cb();
      }
    });
  };

  DummyBackend.prototype.destroy_database = function(name,cb) {
    fs.unlink(this.path(name),function(error) {
      if(error) {
        console.dir(error);
        cb(Couch.Errors.UNKNOWN_ERROR);
      } else {
        cb();
      }
    });
  };

  DummyBackend.prototype.enumerate_databases = function(cb) {
    var that = this;
    var r = new EventEmitter;
    r.pause = function() {
      r.paused = true;
    };
    r.resume = function() {
      r.paused = false;
      r.next();
    };
    r.next = function() {
      if(r.paused) return;
      if(!r.files) {
        r.pause();
        fs.readdir(that.base,function(err,files) {
          if(err) {
            console.dir(err);
            return r.emit('error', Couch.Errors.UNKNOWN_ERROR);
          }
          r.files = files.filter(function(f) { return f.match(/\.couch\.json$/); });
          r.resume();
          return
        });
        return;
      }
      if(r.files.length === 0) {
        r.emit('end');
        return;
      }
      var one = r.files.shift();
      r.emit('data',one);
      r.next();
    };
    cb(null,r);
    r.resume();
  };

  DummyBackend.prototype.retrieve_document_meta = function(db,id,cb) {
    fs.readFile(this.path(db),'utf8',function(err,buf) {
      if(err) {
        console.dir(err);
        return cb(Couch.Errors.UNKNOWN_ERROR);
      }
      var content = JSON.parse(buf);
      if(!content.meta[id]) {
        cb(Couch.Errors.MISSING_DOC);
      } else {
        cb(null,content.meta[id]);
      }
    });
  };

  DummyBackend.prototype.retrieve_document = function(db,id,cb) {
    fs.readFile(this.path(db),'utf8',function(err,buf) {
      if(err) {
        console.dir(err);
        return cb(Couch.Errors.UNKNOWN_ERROR);
      }
      var content = JSON.parse(buf);
      cb(null,content.docs[id]);
    });
  };

  DummyBackend.prototype.update_document = function(db,id,meta,buffer,cb) {
    fs.readFile(this.path(db),'utf8',function(err,buf) {
      if(err) {
        console.dir(err);
        return cb(Couch.Errors.UNKNOWN_ERROR);
      }
      var content = JSON.parse(buf);
      content.meta[id] = meta;
      content.docs[id] = buffer;
      fs.writeFile(this.path(db),JSON.stringify(content),'utf8',function(err) {
        if(error) {
          cb(Couch.Errors.UNKNOWN_ERROR);
        } else {
          cb();
        }
      });
    });
  };

  return DummyBackend;
})();

module.exports = DummyBackend;
