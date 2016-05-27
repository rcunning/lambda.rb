require 'yaml'
require 'fileutils'

desc 'Deploy ruby app to s3+Lambda. Takes source_dir to ruby app, loads all detail from source_dir/lambda.rb.yaml.'
task :deploy, [:source_dir] do |t, args|
  raise 'source_dir is required' unless args.source_dir
  # load the config info
  source_dir = args.source_dir
  config = YAML.load_file(File.join(source_dir, 'lambda.rb.yaml'))
  # make it easier to access these
  config.class_eval do
    def method_missing(name, *args, &block)
      self[name.to_s] || super
    end
  end
  # compute the s3 key, travelling ruby filename
  zip_filename = "#{config.app_name}-#{config.app_version}.zip"
  aws_s3_key = File.join(config.aws_subdir, zip_filename)
  travelling_ruby_filename = "traveling-ruby-#{config.travelling_ruby_version}-#{config.travelling_ruby_os}.tar.gz"

  puts "Creating the build"
  # Clean build dir
  FileUtils::rm_rf('build')
  FileUtils::mkdir_p('build')
  # Create package dir skeleton
  package_dir = "build/#{config.app_name}-#{config.app_version}-#{config.target_os}"
  lib_dir = "#{package_dir}/lib"
  FileUtils::mkdir_p(lib_dir)
  # Copy in the app
  FileUtils::cp_r(File.join(source_dir, 'app'), lib_dir)
  # Uncompress the appropriate Ruby into it
  puts "Checking for #{travelling_ruby_filename}"
  target_file = "packaging/#{travelling_ruby_filename}"
  if File.exists?(target_file)
    puts "Already have it"
  else
    url = "http://d6r77u77i8pq3.cloudfront.net/releases/#{travelling_ruby_filename}"
    puts "Downloading #{url}"
    execute("curl -s -L -O --fail '#{url}' > #{target_file}")
  end
  # Uncompress the appropriate Ruby into it
  ruby_dir = File.join(package_dir, 'lib', 'ruby')
  FileUtils::mkdir_p(ruby_dir)
  execute("tar -xzf '#{File.join('packaging', traveling_ruby_path)}' -C '#{ruby_dir}'")

  puts "Bundling"
  # Copy in Bundler and gems
  tmp_dir = File.join('packaging', 'tmp')
  FileUtils::mkdir_p(tmp_dir)
  FileUtils::cp(File.join(source_dir, 'app','Gemfile*'), tmp_dir)
  execute("cd #{tmp_dir} && BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development")
  FileUtils::rm_rf(tmp_dir)
  FileUtils::rm_rf(File.join('packaging', 'vendor', '*', '*', 'cache', '*'))
  FileUtils::cp_r(File.join('packaging', 'vendor'), lib_dir)
  FileUtils::cp(File.join(source_dir, 'app','Gemfile*'), File.join(lib_dir, 'vendor'))
  FileUtils::mkdir(File.join(lib_dir, 'vendor', '.bundle'))
  FileUtils::cp(File.join('packaging', 'bundler-config'), File.join(lib_dir, 'vendor', '.bundle', 'config'))
  FileUtils::cp(File.join('packaging', 'wrapper.sh'), File.join(package_dir, 'app'))

  puts "Zipping for Lambda"
  # Add Lambda wrapper and zip it all up for deploy
  FileUtils::cp('index.js', package_dir)
  execute("cd #{package_dir} && find . | zip \"#{File.join('..', zip_filename)}\" -@")
  package_zip = "#{package_dir}.zip"

  # Clean up files
  FileUtils::rm_rf(package_dir)

  puts "Copying to S3"
  execute("aws s3api put-object --bucket #{config.aws_bucket} --key #{aws_key} --body #{package_zip} --profile #{config.aws_profile}")


  puts "Updating Lambda"
  execute("aws lambda update-function-code --function-name #{config.function_name} --s3-bucket #{config.aws_bucket} --s3-key #{aws_key} --profile #{config.aws_profile}")

  puts "Done!"
end

def execute(cmd)
  raise "Failed to execute #{cmd}" if !system(cmd)
end