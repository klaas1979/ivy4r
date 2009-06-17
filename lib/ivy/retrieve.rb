require 'ivy/target'

module Ivy
  class Retrieve < Ivy::Target
    def parameter
      [
        Parameter.new(:pattern, false),
        Parameter.new(:ivypattern, false),
        Parameter.new(:conf, false),
        Parameter.new(:sync, false),
        Parameter.new(:type, false),
        Parameter.new(:symlink, false),
        Parameter.new(:settingsRef, false),
        Parameter.new(:log, false)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_retrieve => params
    end

    def create_return_values
      nil
    end
  end
end