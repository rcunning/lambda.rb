var spawn = require('child_process').spawn;

exports.handler = function(event, context) {
  // setup paths and env
  var bin = __dirname + '/lib/ruby/bin/ruby';
  var app = __dirname + '/lib/app/app.rb';
  var args = [app];
  spawnEnv = {};
  for (e in process.env) {
    if (e != 'BUNDLE_IGNORE_CONFIG') {
      spawnEnv[e] = process.env[e];
    }
  }
  spawnEnv.BUNDLE_GEMFILE = __dirname + '/lib/vendor/Gemfile';
  // be sure to include our bundled gems in the GEM_PATH as well
  spawnEnv.GEM_PATH = process.env.GEM_PATH + ":" + __dirname + '/lib/vendor/ruby/2.2.0/gems';
  var options = { env: spawnEnv };

  // cd to our dir and launch the child process
  process.chdir(__dirname);
  var child = spawn(bin, args, options);
  var out_data = '';

  // collect all output in chunks
  child.stdout.on('data', function(data) {
    if (data) {
      out_data += data;
    }
  });
  // log errors
  child.stderr.on('data', function(data) {
    if (data) {
      console.log(data.toString());
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