require 'ivy/target'

module Ivy
  class Cleancache < Ivy::Target
    def parameter
      [
        Parameter.new(:settingsRef, false)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_cleancache => params
    end
    
    def create_return_values
      nil
    end
  end
end