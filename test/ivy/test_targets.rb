$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'ivy/targets'
require 'ivy4r'

module Ivy
  class TargetsTest < Test::Unit::TestCase

    def setup
      ivy4r = Ivy4r.new
      ivy4r.ant_home = File.join(File.dirname(__FILE__), '..', '..', 'jars')
      ivy4r.lib_dir = ivy4r.ant_home
      @ivy_test_xml = File.join(File.dirname(__FILE__), 'ivytest.xml')
      @info = Ivy::Info.new(ivy4r.ant)
    end

    def test_execute_empty_parameters_missing_mandatory_exception
      assert_raise(ArgumentError) { @info.execute({}) }
    end

    def test_execute_validate_with_unkown_parameter_exception
      assert_raise(ArgumentError) { @info.execute(:unknown_parameter => 'unknown') }
    end

    def test_execute_simple_file_correct_return_values
      result = @info.execute(:file => @ivy_test_xml)

      assert_not_nil result
      %w[ivy.organisation ivy.revision ivy.module].each do |var|
        assert_equal true, result.keys.member?(var), "Contains key '#{var}', has '#{result.keys.join(', ')}'"
      end
      assert_equal 'blau', result['ivy.organisation']
    end
  end
end
