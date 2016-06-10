var spawn = require('child_process').spawn;

var invokeRubyApp = "./app";

exports.handler = function(event, context) {
  console.log("Starting process: " + invokeRubyApp);
  var child = spawn(invokeRubyApp);
  var out_data = '';

  child.stdout.on('data', function(data) { out_data += data; });
  child.stderr.on('data', function(data) { console.log("stderr:\n" + data); });

  child.on('close', function(code) {
    if(code === 0) {
      context.succeed(JSON.parse(out_data));
    } else {
      context.fail(new Error("Process exited with non-zero status code " + code));
    }
  });

  child.stdin.end(JSON.stringify(event));
}