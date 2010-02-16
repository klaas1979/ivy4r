require 'ivy/target'

module Ivy
  class Listmodules < Ivy::Target
    def parameter
      [
        Parameter.new(:organisation, true),
        Parameter.new(:module, true),
        Parameter.new(:branch, false),
        Parameter.new(:revision, true),
        Parameter.new(:matcher, false),
        Parameter.new(:property, true),
        Parameter.new(:value, true),
        Parameter.new(:settingsRef, false),
      ]
    end

    protected
    def before_hook
      @cached_property_names = ant_properties.map {|key, value| key }
    end

    def after_hook
      @cached_property_names = nil
    end

    def execute_ivy
      call_nested :ivy_listmodules => params
    end

    def create_return_values
      ant_properties.reject { |key, value| @cached_property_names.member? key }
    end
  end
end