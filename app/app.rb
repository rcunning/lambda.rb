#!/usr/bin/env ruby

begin
  # load all the rb files in the app dir
  Dir[File.join(File.dirname(__FILE__), '*.rb')].each {|file| require file if file != __FILE__}
  # initialize an Application object and call its handler
  print Application.init.handler($stdin.read).to_json
rescue => e
  $stderr.write("Exception: #{e}, #{e.backtrace}")
  raise
end