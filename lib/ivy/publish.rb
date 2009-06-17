require 'ivy/target'

module Ivy
  class Publish < Ivy::Target
    def parameter
      [
        Parameter.new(:artifactspattern, false),
        Parameter.new(:resolver, true),
        Parameter.new(:pubrevision, false),
        Parameter.new(:pubbranch, false),
        Parameter.new(:forcedeliver, false),
        Parameter.new(:update, false),
        Parameter.new(:validate, false),
        Parameter.new(:replacedynamicrev, false),
        Parameter.new(:publishivy, false),
        Parameter.new(:conf, false),
        Parameter.new(:overwrite, false),
        Parameter.new(:warnonmissing, false),
        Parameter.new(:srcivypattern, false),
        Parameter.new(:srcivypattern, false),
        Parameter.new(:pubdate, false),
        Parameter.new(:status, false),
        Parameter.new(:delivertarget, false),
        Parameter.new(:settingsRef, false)
      ]
    end
    
    protected
    def execute_ivy
      call_nested :ivy_publish => params
    end

    def create_return_values
      nil
    end
  end
end