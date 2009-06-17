require 'ivy/target'

module Ivy
  class Configure < Ivy::Target
    def parameter
      [
        Parameter.new(:id, false),
        Parameter.new(:file, false),
        Parameter.new(:url, false),
        Parameter.new(:host, false),
        Parameter.new(:realm,false),
        Parameter.new(:username, false),
        Parameter.new(:passwd, false)
      ]
    end

    def result_property_values
      property = params[:id] || 'ivy.instance'
      [
        ResultValue.new(/.*\.#{property}/, nil)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_configure => params
    end
  end
end
