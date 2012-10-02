var dummy_backend = require('../backends/dummy');

var couch = require('../src/couch');
var opts = {
  backend: new dummy_backend('/tmp')
, port: 3000
};
couch(opts);
console.log("Chesterfield running on port "+opts.port);
