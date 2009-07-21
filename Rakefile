# -*- ruby -*-
$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'hoe'
require 'ivy4r'
  
hoe = Hoe.spec 'ivy4r' do |p|
  self.rubyforge_name = 'hamburgrb'
  p.developer('Klaas Prause', 'klaas.prause@googlemail.com')
  p.remote_rdoc_dir = 'ivy4r'
  p.extra_deps << ['Antwrap', '>=0.7.0']
  p.extra_deps << ['ivy4r-jars', '>=1.0.0']
  p.extra_deps << ['facets', '>=2.5.2']
  #p.extra_deps << ['thoughtbot-shoulda', '>=2.5.2']
  #p.extra_deps << ['rr', '>=0.10.0']
  File.open(File.join(File.dirname(__FILE__), 'VERSION'), 'w') do |file|
    file.puts Ivy4r::VERSION
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new(hoe.spec)
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :gemspec => :test

desc "Tests, releases and publishs docs to rubyforge"
task :release_and_publish => [:test, :release, :publish_docs]

# vim: syntax=ruby
