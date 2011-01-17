require 'ivy/target'

module Ivy
  class Install < Ivy::Target
    def parameter
      [
        Parameter.new(:from, true),
        Parameter.new(:to, true),
        Parameter.new(:organisation, true),
        Parameter.new(:module, true),
        Parameter.new(:branch, false),
        Parameter.new(:revision, true),
        Parameter.new(:type, false),
        Parameter.new(:validate, false),
        Parameter.new(:overwrite, false),
        Parameter.new(:transitive, false),
        Parameter.new(:matcher, false),
        Parameter.new(:settingsRef, false),
        Parameter.new(:haltonfailure, false)
      ]
    end
    
    def create_return_values
      nil
    end

    protected
    
    def execute_ivy
      call_nested :ivy_install => params
    end

  end
end