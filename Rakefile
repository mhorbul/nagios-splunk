require 'rake/testtask'
require 'rake/gempackagetask'

task :default => :test

desc "Run tests"
Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

gem_spec = eval(File.read("nagios-splunk.gemspec"))

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.gem_spec = gem_spec
end

desc "remove build files"
task :clean do
  sh %Q{ rm -f pkg/*.gem }
end
