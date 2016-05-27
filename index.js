var spawn = require('child_process').spawn;

var invokeRubyApp = "./app";

exports.handler = function(event, context) {
  console.log("Starting process: " + invokeRubyApp);
  var child = spawn(invokeRubyApp, [ JSON.stringify(event) ]); //, { stdio: 'inherit' });
  var out_data = '';

  child.stdout.on('data', function(data) { out_data += data; });
  child.stderr.on('data', function(data) { console.log("stderr:\n" + data); });

  child.on('close', function(code) {
    if(code === 0) {
      context.succeed(out_data);
    } else {
      context.fail(new Error("Process exited with non-zero status code " + code));
    }
  });
}