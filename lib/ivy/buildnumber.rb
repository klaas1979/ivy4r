require 'ivy/target'

module Ivy
  class Buildnumber < Ivy::Target
    def parameter
      [
        Parameter.new(:organisation, true),
        Parameter.new(:module, true),
        Parameter.new(:branch, false),
        Parameter.new(:revision, false),
        Parameter.new(:default, false),
        Parameter.new(:defaultBuildNumber, false),
        Parameter.new(:revSep, false),
        Parameter.new(:prefix, false),
        Parameter.new(:settingsRef, false),
        Parameter.new(:resolver, false)
      ]
    end

    def result_property_values
      [
        ResultValue.new("ivy.revision", nil),
        ResultValue.new("ivy.new.revision", nil),
        ResultValue.new("ivy.build.number", nil),
        ResultValue.new("ivy.new.build.number", nil)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_buildnumber => params
    end
  end
end