require 'ivy/target'

module Ivy
  class Makepom < Ivy::Target
    def parameter
      [
        Parameter.new(:ivyfile, true),
        Parameter.new(:pomfile, true),
        Parameter.new(:nested, true),
        Parameter.new(:settingsRef, false)
      ]
    end

    protected
    def execute_ivy
      call_nested :ivy_makepom => params
    end

    def create_return_values
      IO.read(params[:pomfile])
    end
  end
end