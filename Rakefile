require 'yaml'
require 'json'
require 'fileutils'
require 'open3'

desc 'Copy template files and default lambda.rb.yaml to source_dir. Takes source_dir to new ruby app.'
task :create, [:source_dir] do |t, args|
  source_dir = default_source_dir(args.source_dir)
  if File.exists?(File.join(source_dir, 'lambda.rb.yaml'))
    raise 'Cannot create since project already exists. Please use update to update the non-template files.'
  end
  puts "Creating #{source_dir}"
  FileUtils::mkdir_p(source_dir)
  puts "Copying app template and classes to #{source_dir}/app"
  FileUtils::cp_r('app', source_dir + File::SEPARATOR)
  puts "Creating default config file #{source_dir}/lambda.rb.yaml"
  File.open(File.join(source_dir, 'lambda.rb.yaml'), 'w') do |f|
    f.write(File.read('lambda.rb.yaml').gsub(/hello-world/, File.basename(source_dir)))
  end
  puts "Copying index.js lambda handler"
  FileUtils::cp('index.js', File.join(source_dir, 'index.js'))
end

desc 'Update class files in source_dir. Takes source_dir to ruby app.'
task :update, [:source_dir] do |t, args|
  source_dir = default_source_dir(args.source_dir)
  puts "Copying app classes to #{source_dir}/app"
  Dir["app/**/*.rb"].each do |filename|
    FileUtils::mkdir_p(File.dirname(File.join(source_dir, filename)))
    FileUtils::cp(filename, File.join(source_dir, filename))
  end
  puts "Copying index.js lambda handler"
  FileUtils::cp('index.js', File.join(source_dir, 'index.js'))
end

desc 'Deploy ruby app to s3+Lambda. Takes source_dir to ruby app, loads all detail from source_dir/lambda.rb.yaml.'
task :deploy, [:source_dir] do |t, args|
  # load the config info a hash
  source_dir = default_source_dir(args.source_dir)
  config = YAML.load_file(File.join(source_dir, 'lambda.rb.yaml'))
  # make it easier to access these
  config.instance_eval do
    def method_missing(name, *args, &block)
      self[name.to_s] || super
    end
  end
  # compute the s3 key, travelling ruby filename
  zip_filename = "#{config.app_name}-#{config.app_version}-#{config.travelling_ruby_os}.zip"
  aws_s3_key = File.join(config.aws_subdir, zip_filename)
  travelling_ruby_filename = "traveling-ruby-#{config.travelling_ruby_version}-#{config.travelling_ruby_os}.tar.gz"

  puts "Creating the build from #{source_dir}"
  # Clean build dir
  FileUtils::rm_rf('build')
  FileUtils::mkdir_p('build')
  # Create package dir skeleton
  package_dir = "build/#{config.app_name}-#{config.app_version}-#{config.travelling_ruby_os}"
  lib_dir = "#{package_dir}/lib"
  # make sure it is empty
  FileUtils::rm_rf(package_dir)
  FileUtils::mkdir_p(lib_dir)
  # Copy in the app
  FileUtils::cp_r(File.join(source_dir, 'app'), lib_dir)
  # Uncompress the appropriate Ruby into it
  puts "Checking for #{travelling_ruby_filename}"
  traveling_ruby_path = "packaging/#{travelling_ruby_filename}"
  if File.exists?(traveling_ruby_path)
    puts "Already have it"
  else
    url = "http://d6r77u77i8pq3.cloudfront.net/releases/#{travelling_ruby_filename}"
    puts "Downloading #{url}"
    execute("curl -s -L --fail '#{url}' > #{traveling_ruby_path}")
  end
  # Uncompress the appropriate Ruby into it
  ruby_dir = File.join(package_dir, 'lib', 'ruby')
  FileUtils::mkdir_p(ruby_dir)
  execute("tar -xzf '#{traveling_ruby_path}' -C '#{ruby_dir}'")

  gemfile = File.join(source_dir, 'app','Gemfile')
  if File.exists?(gemfile)
    puts "\nBundling"
    # Copy in Bundler and gems
    tmp_dir = File.join('packaging', 'tmp')
    FileUtils::mkdir_p(tmp_dir)
    FileUtils::cp(Dir.glob("#{gemfile}*"), tmp_dir)
    execute("cd #{tmp_dir} && BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development")
    FileUtils::rm_rf(tmp_dir)
    FileUtils::rm(Dir.glob(File.join('packaging', 'vendor', '*', '*', 'cache', '*')))
    FileUtils::cp_r(File.join('packaging', 'vendor'), lib_dir)
    FileUtils::cp(Dir.glob(File.join(source_dir, 'app', 'Gemfile*')), File.join(lib_dir, 'vendor'))
    FileUtils::mkdir(File.join(lib_dir, 'vendor', '.bundle'))
    FileUtils::cp(File.join('packaging', 'bundler-config'), File.join(lib_dir, 'vendor', '.bundle', 'config'))
  else
    puts "No Gemfile, skipping bundle install"
  end

  puts "\nZipping for Lambda"
  # zip it all up for deploy
  FileUtils::cp(File.join(source_dir, 'index.js'), package_dir)
  execute("cd #{package_dir} && find . | zip \"#{File.join('..', zip_filename)}\" -@")
  zip_path = File.join('build', zip_filename)

  # Clean up files
  FileUtils::rm_rf(package_dir)

  puts "\nCopying to S3"
  execute("aws s3api put-object --bucket #{config.aws_bucket} --key #{aws_s3_key} --body #{zip_path} --profile #{config.aws_profile}")


  puts "\nUpdating Lambda"
  execute("aws lambda update-function-code --function-name #{config.function_name} --s3-bucket #{config.aws_bucket} --s3-key #{aws_s3_key} --profile #{config.aws_profile}")

  puts "\nDone!"
end

desc 'Run your app with a test input, return the output. Note, expects correct ruby is default gems are install.'
task :test, [:test_file, :source_dir] do |t,args|
  source_dir = default_source_dir(args.source_dir)
  raise "test_file is required" unless args.test_file
  # prefer source_dir test file, then look in local
  test_filename = "#{args.test_file}.json"
  test_path = File.join(source_dir, 'test', test_filename)
  test_path = File.join('test', test_filename) unless File.exists?(test_path)
  # read the input, launch locally
  cmd = "cd #{source_dir} && unset BUNDLE_IGNORE_CONFIG && BUNDLE_GEMFILE=#{File.join(source_dir, 'app', 'Gemfile')} ruby #{File.join(source_dir, 'app', 'app.rb')}"
  Open3.popen3(cmd) do |stdin, stdout, stderr|
    stdin.write(File.read(test_path))
    stdin.close_write
    out = stdout.read
    err = stderr.read
    if err.to_s.empty?
      puts out
    else
      puts "Output:"
      puts out
      puts "Error:"
      puts err
    end
  end
end

# helper methods
def execute(cmd)
  raise "Failed to execute #{cmd}" if !system(cmd)
end

def default_source_dir(source_dir)
  last_source_dir_filename = '.last_source_dir'
  if source_dir.nil? && File.exists?(last_source_dir_filename)
    puts "Loading source_dir from #{last_source_dir_filename}"
    source_dir = File.read(last_source_dir_filename)
  end
  raise 'source_dir is required' unless source_dir
  File.write(last_source_dir_filename, source_dir)
  source_dir
end
