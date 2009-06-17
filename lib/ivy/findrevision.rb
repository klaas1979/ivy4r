require 'ivy/target'

module Ivy
  class Findrevision < Ivy::Target
    def parameter
      [
        Parameter.new(:organisation, true),
        Parameter.new(:module, true),
        Parameter.new(:branch, false),
        Parameter.new(:revision, true),
        Parameter.new(:property, false),
        Parameter.new(:settingsRef, false)
      ]
    end

    def result_property_values
      property = params[:property] || 'ivy.revision'
      [
        ResultValue.new("#{property}", nil)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_findrevision => params
    end

    def create_return_values
      values = result_properties.values
      raise "Could not retrieve revision for '#{params.inspect}'" if values.size > 1
      values.size == 1 ? values[0] : nil
    end
  end
end