var spawn = require('child_process').spawn;

exports.handler = function(event, context) {
  // setup paths and env
  var bin = __dirname + '/lib/ruby/bin/ruby';
  var app = __dirname + '/lib/app/app.rb';
  var options = { env:
    { 'BUNDLE_GEMFILE': __dirname + '/lib/vendor/Gemfile',
      'BUNDLE_IGNORE_CONFIG': null }
  };

  // launch the child process
  var child = spawn(bin, [app], options);
  var out_data = '';

  // collect all output in chunks
  child.stdout.on('data', function(data) {
    if (data !== null) {
      out_data += data;
    }
  });
  // log errors
  child.stderr.on('data', function(data) {
    if (data !== null) {
      console.log("stderr:\n" + data);
    }
  });
  // complete the lambda handler on close
  child.on('close', function(code) {
    if(code === 0) {
      context.succeed(JSON.parse(out_data));
    } else {
      context.fail(new Error("Process exited with non-zero status code " + code));
    }
  });
  // all handlers set, send the event data to start processing
  child.stdin.end(JSON.stringify(event));
}