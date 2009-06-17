require 'ivy/target'

module Ivy
  class Artifactreport < Ivy::Target
    def parameter
      [
        Parameter.new(:tofile, true),
        Parameter.new(:pattern, false),
        Parameter.new(:conf, false),
        Parameter.new(:haltonfailure, false),
        Parameter.new(:settingsRef, false)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_artifactreport => params
    end

    def create_return_values
      IO.read(params[:tofile])
    end
  end
end