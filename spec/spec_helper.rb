require 'ivy4r'
Bundler.require(:default, :development)

require 'rspec'

JRuby.objectspace = true if RUBY_PLATFORM == 'java'

Rspec.configure do |c|
  c.mock_with :rr
end
