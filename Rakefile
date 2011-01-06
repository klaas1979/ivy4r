require "rubygems"
require "bundler"
require "rake"
require "rake/testtask"

$:.unshift File.join(File.dirname(__FILE__),'lib')
require "ivy4r/version"

# Todo
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new :spec
#task :default => :spec

desc "Functional test execution not that this only works under MRI and not with JRuby 1.5.1"
Rake::TestTask.new :test_functional do |t|
  Bundler.require :development
  t.test_files = FileList['test-functional/**/test*.rb']
  t.verbose = true
end

task :build => :test_functional do
  system "gem build ivy4r.gemspec"
end
 
task :release => :build do
  system "gem push ivy4r-#{Ivy4r::VERSION}"
end

# Todo
begin
  require "hanna/rdoctask"

  Rake::RDocTask.new do |t|
    t.title = "Ivy4r - Ruby interface to Apache Ivy dependency management with integration for Buildr and Rake"
    t.rdoc_dir = "doc"
    t.rdoc_files.include("**/*.rdoc").include("lib/**/*.rb")
    t.options << "--line-numbers"
    t.options << "--webcvs=http://github.com/klaas1979/ivy4r/tree/master/"
  end
rescue LoadError
  puts "'gem install hanna' to generate documentation"
end
