require 'ivy/target'

module Ivy
  class Artifactproperty < Ivy::Target
    def parameter
      [
        Parameter.new(:name, true),
        Parameter.new(:value, true),
        Parameter.new(:conf, false),
        Parameter.new(:haltonfailure, false),
        Parameter.new(:validate, false),
        Parameter.new(:overwrite, false),
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
      call_nested :ivy_artifactproperty => params
    end

    def create_return_values
      ant_properties.reject { |key, value| @cached_property_names.member? key }
    end
  end
end