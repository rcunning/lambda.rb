#!/usr/bin/env ruby

# load all the rb files in the app dir
Dir[File.join(File.dirname(__FILE__), '*.rb')].each {|file| require file if file != __FILE__}
# initialize an Application object and call its handler
print Application.init.handler(ARGV[0])