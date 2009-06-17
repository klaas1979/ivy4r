require 'ivy/target'

module Ivy
  class Resolve < Ivy::Target
    def parameter
      [
        Parameter.new(:file, false),
        Parameter.new(:conf, false),
        Parameter.new(:refresh, false),
        Parameter.new(:resolveMode, false),
        Parameter.new(:inline, false),
        Parameter.new(:keep, false),
        Parameter.new(:organisation, false),
        Parameter.new(:module, false),
        Parameter.new(:revision, false),
        Parameter.new(:branch, false),
        Parameter.new(:type, false),
        Parameter.new(:haltonfailure, false),
        Parameter.new(:failureproperty, false),
        Parameter.new(:transitive, false),
        Parameter.new(:showprogress, false),
        Parameter.new(:validate, false),
        Parameter.new(:settingsRef, false),
        Parameter.new(:resolveId, false),
        Parameter.new(:log, false)
      ]
    end

    def result_property_values
      property = params[:resolveId] ? ".#{params[:resolveId]}" : ''
      [
        ResultValue.new("ivy.organisation#{property}", nil),
        ResultValue.new("ivy.module#{property}", nil),
        ResultValue.new("ivy.revision#{property}", nil),
        ResultValue.new("ivy.resolved.configurations#{property}", Ivy::COMMA_SPLITTER)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_resolve => params
    end
  end
end