module.exports = function(opts) {
  var express = require('express');
  var app = express(opts);

  include(app);

  if(!opts.port) {
    opts.port = 5984;
  }
  app.listen(opts.port);
  return app;
}

var include = function(app) {
  //   update_document, db, doc_id, meta, body_buffer  # error, end
  // Events:
  //   # error occurred (final)
  //   'error', (error) ->
  //   # successful completion (final)
  //   'end'
  //   # one more to retrieve data
  //   'data'

  var backend = null;

  var motd = 'Welcome';

  // Trying to figure out the API
  // Is the list on
  //   http://wiki.apache.org/couchdb/Complete_HTTP_API_Reference
  // actually accurate and complete?

  var start_json = function(res) {
    var headers = {
      'Content-Type': 'application/json'
    , 'Cache-Control': 'must-revalidate'
    };
    res.writeHead( 200, headers );
  };

  var send_error = function (res,error) {
    res.writeHead(error.status,error.error);
    res.json(error);
  }

  var push_revision = function(res,db,doc,meta,body) {
    meta.rev = body._rev = meta.version + '-' + new_uuid();
    var body_as_json = JSON.stringify(body);
    var body_buffer = new Buffer(body_as_json);
    meta.etag = md5sum_as_hex(body_buffer);
    meta.length = body_buffer.length;
    backend.update_seq(function(error,seqnum){
      if(error) return send_error(res,error);
      meta.local_seq = seqnum;
      backend.update_document( req.params.db, req.params.doc, meta, body_as_json, function (error) {
        if(error) return send_error(res,error);
        res.json({ok:true});
      });
    });
  };

  // Actions maked 'system' are most probably implementation-dependent.
  // Review what BigCouch et al. do for these.

  // ### Server-level misc. methods
  app.get('/', function(req,res) {
    // http://wiki.apache.org/couchdb/HttpGetRoot
    // Note: Apache CouchDB sends text/plain, not json
    res.json({
      pouchdb: "Welcome"
    , version: "0.1.0"
    });
  });

  // @get '/favicon.ico': ->
  app.use(express.favicon());

  app.get( '/_all_dbs', function(req,res) {
      // http://wiki.apache.org/couchdb/HttpGetAllDbs
      // Note: Apache CouchDB sends text/plain, not json
      // Note: this could be a very long list.
      // Note: Apache CouchDB provides a Content-Length for it??
      var started = false;
      backend.enumerate_databases(function(error,stream) {
        if(error) return send_error(res,error);
        stream.on('data',function(name){
          res.write(started?',':'[');
          started = true;
          res.write(JSON.stringify(name));
        });
        stream.on('end',function(){
          res.end(started?']':'[]');
        });
        stream.on('error',function(error){ send_error(res,error); });
      });
  });

  /*
  app.get '/_active_tasks', function(req,res) { // system
    res.writeHead 500
  };
  */
  /*
  app.post '/_replicate', function(req,res) {
    res.writeHead 500 // re-use mikeal/replicate here
  };
  */

  // @all '/_replicator', function() {
  //   replace with a normal database,
  //   with an external replicator process monitoring its _changes

  /*
  backend.create_database '_replicator'
  monitor_database '_replicator', (change) function() {
    // start/stop a given replication
  start_replicators()
  */

  var couch_uuid = require('./uuids');

  // http://wiki.apache.org/couchdb/HttpGetUuids
  /*
  app.get( '/_uuids', function() {
    var count = req.query.count ? 1;
    var uuids = [];
    couch_uuid( function(e,value) {
        if e
          res.writeHead 500
        else
          uuids.push value
          if i is count
            @json uuid: uuids
          else
            r()
    });
  })
  */

  /*
  app.post '/_restart' // system
  app.get '/_stats'    // system
  app.get '/_log'      // system
  */

  // @get '/_utils/*'
  //   replace with a normal database (if possible
  //   based on paths) so that futon or futon2 may be used

  // Note: we make _utils a couchapp, à la futon2
  /*
  ensure_database '_utils'
  push_app '_utils'
  */

  // ### Server configuration
  // system?
  /*
  app.get '/_config'
  app.get '/_config/:section'
  app.get '/_config/:section/:key'
  app.put '/_config/:section/:key'
  app.del '/_config/:section/:key'
  */

  // ### Authentication
  // Related note: authentication at query time is done by a specific
  // middleware, which requests auth based on configuration and path
  // (e.g. /_utils should probably be public and never request auth).
  /*
  app.get '/_session'
  app.post '/_session'
  app.del '/_session'
  */
  // I'll probably let someone more clever than me implement those..
  /*
  app.get '/_oauth/access_token'
  app.get '/_oauth/authorize'
  app.post '/_oauth/authorize'
  app.all '/_oauth/request_token'
  */

  // ### User database
  // This is a regular database
  // @all '/_users'
  /*
  ensure_database '_users'
  push_app '_users'
  */

  // ### Database methods
  // Note: restrict db names to proper syntax (what is it?)
  // (At least cannot start with underscore.)
  app.get( '/:db', function(req,res) {
    res.json({
      name: req.params.db
    });
  });

  app.put( '/:db', function(req,res) {
    backend.create_database( req.params.db, function (error) {
      if(error) return send_error(res,error);
      res.json({ok:true});
    });
  });

  app.del( '/:db', function(req,res) {
    backend.destroy_database( req.params.db, function (error) {
      if(error) return send_error(res,error);
      res.json({ok:true});
    });
  });

  /*
  app.get '/:db/_changes', function() {
  */

  /*
  app.post '/:db/_compact' // system
  app.post '/:db/_compact/:design' // system
  app.post '/:db/_view_cleanup' // system
  app.post '/:db/_temp_view' // I think BigCouch did away with those
  app.post '/:db/_ensure_full_commit'
  app.post '/:db/_bulk_docs'
  app.post '/:db/_purge'
  app.get '/:db/_all_docs' // It'd be really nice to make it behave like real views though
  app.post '/:db/_all_docs'
  app.post '/:db/_missing_revs'
  app.post '/:db/_revs_diff'
  app.get '/:db/_security'
  app.put '/:db/_security'
  app.get '/:db/_revs_limit'
  app.put '/:db/_revs_limit'
  */

  // ### Database document methods
  // Note: resttrict doc names to valid ones (what are they?)
  // At least, cannot start with underscore.
  /*
  app.post '/:db', function() {
  */

  app.get( '/:db/:doc', function(req,res) {
    backend.retrieve_document( req.params.db, req.params.doc, function (error,doc) {
      if(error) return send_error(res,error);
      res.json(doc);
    });
  });

  /*
  app.head( '/:db/:doc', function(req,res) {
    backend.retrieve_document_meta( req.params.db, req.params.doc, function (error,meta) {
      if(error) return send_error(res,error);
      res.writeHead
      res.end();
    });
  });
  */

  app.put( '/:db/:doc', function(req,res) {
    var db = req.params.db;
    var doc = req.params.doc;
    backend.retrieve_document_meta( db, doc, function (error,meta) {
      if(error === Couch.Errors.MISSING_DOC) {
        // New document
        if( req.body._rev !== null ) {
          send_error(res,Couch.Errors.REV_CONFLICT); // FIXME is this the same error apache couchdb sends?
          return;
        }
        // Create new meta
        var new_meta = {
          id: req.body._id
        , version: 1
        };
        push_revision( res, db, doc, new_meta, req.body );
      }
      if(error) return send_error(res,error);

      // Check revision
      if( req.body._rev !== meta.rev ) {
        send_error(res,Couch.Errors.REV_CONFLICT);
        return;
      }
      // Check ID is consistent
      if( req.body._id !== meta.id ) {
        send_error(res,Couch.Errors.INVALID_ID); // FIXME is this the same error apache couchdb sends?
        return;
      }
      // Create new meta
      var new_meta = {
        id: meta.id
      , version: meta.version+1
      };
      push_revision( res, db, doc, new_meta, req.body );
    });
  });

  /*
  app.del  '/:db/:doc'
  app.copy '/:db/:doc'
  // ### Attachments
  app.get  '/:db/:doc/*'
  app.put  '/:db/:doc/*'
  app.del  '/:db/:doc/*'
  // ### Non-replicating documents
  app.get  '/:db/_local/:doc'
  app.put  '/:db/_local/:doc'
  app.del  '/:db/_local/:doc'
  app.copy '/:db/_local/:doc'
  // ### Design documents
  app.get  '/:db/_design/:design'
  app.put  '/:db/_design/:design'
  app.del  '/:db/_design/:design'
  app.copy '/:db/_design/:design'
  // ### Design documents attachments
  // Note: attachment name cannot start with underscore
  app.get  '/:db/_design/:design/*'
  app.put  '/:db/_design/:design/*'
  app.del  '/:db/_design/:design/*'

  // ### Special design document handlers
  // Info
  app.get  '/:db/_design/:design/_info'
  // Views
  app.get  '/:db/_design/:design/_view/:view'
  app.post '/:db/_design/:design/_view/:view'
  // Shows
  app.get  '/:db/_design/:design/_show/:show'
  app.get  '/:db/_design/:design/_show/:show/*'
  // Lists
  app.get  '/:db/_design/:design/_list/:list/:view'
  app.post '/:db/_design/:design/_list/:list/:view'
  app.get  '/:db/_design/:design/_list/:list/:other_design/:view'
  app.post '/:db/_design/:design/_list/:list/:other_design/:view'
  // Update
  app.put  '/:db/_design/:design/_update/:update'
  app.post '/:db/_design/:design/_update/:update'
  app.put  '/:db/_design/:design/_update/:update/:doc'
  app.post '/:db/_design/:design/_update/:update/:doc'
  // Rewrite
  app.all  '/:db/_design/:design/_rewrite/:rewrite/*'
  */

  // Is that it?
};
