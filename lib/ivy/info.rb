require 'ivy/target'

module Ivy
  class Info < Ivy::Target
    def parameter
      [
        Parameter.new(:file, true),
        Parameter.new(:organisation, false),
        Parameter.new(:module, false),
        Parameter.new(:branch, false),
        Parameter.new(:revision, false),
        Parameter.new(:property, false),
        Parameter.new(:settingsRef, false)
      ]
    end

    def result_property_values
      property = params[:property] || 'ivy'
      [
        ResultValue.new("#{property}.organisation", nil),
        ResultValue.new("#{property}.module", nil),
        ResultValue.new("#{property}.branch", nil),
        ResultValue.new("#{property}.revision", nil),
        ResultValue.new("#{property}.status", nil),
        ResultValue.new(/#{property}.extra\..*/, nil),
        ResultValue.new("#{property}.configurations", Ivy::COMMA_SPLITTER),
        ResultValue.new("#{property}.public.configurations", Ivy::COMMA_SPLITTER)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_info => params
    end
  end
end