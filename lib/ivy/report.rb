require 'ivy/target'

module Ivy
  class Report < Ivy::Target
    def parameter
      [
        Parameter.new(:todir, false),
        Parameter.new(:nested, false),
        Parameter.new(:outputpattern, false),
        Parameter.new(:xsl, false),
        Parameter.new(:xml, false),
        Parameter.new(:graph, false),
        Parameter.new(:dot, false),
        Parameter.new(:conf, false),
        Parameter.new(:organisation, false),
        Parameter.new(:module, false),
        Parameter.new(:validate, false),
        Parameter.new(:xslfile, false),
        Parameter.new(:settingsRef, false),
        Parameter.new(:resolveId, false)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_report => params
    end

    def create_return_values
      nil
    end
  end
end