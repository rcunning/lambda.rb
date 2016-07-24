#!/usr/bin/env ruby

begin
  if File.exists?(File.join(File.dirname(__FILE__), 'Gemfile'))
    # only load up gems from bundler if needed
    require 'bundler/setup'
  end
  # load all the rb files in the app dir
  Dir[File.join(File.dirname(__FILE__), '*.rb')].each {|file| require file if file != __FILE__}
  # initialize an Application object and call its handler
  print Application.init.handler($stdin.read).to_json
rescue => e
  $stderr.write("Exception: #{e}, #{e.backtrace}")
  raise
end