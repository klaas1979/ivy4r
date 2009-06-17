# -*- ruby -*-
$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'hoe'
require 'ivy4r'

hoe = Hoe.spec 'ivy4r' do |p|
  # self.rubyforge_name = 'ivy4rx' # if different than 'ivy4r'
  p.developer('Klaas Prause', 'klaas.prause@googlemail.com')
  p.extra_deps = [['Antwrap', '>=0.7.0']]
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

# vim: syntax=ruby
