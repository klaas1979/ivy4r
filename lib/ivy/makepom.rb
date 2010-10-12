require 'ivy/target'

module Ivy
  class Makepom < Ivy::Target
    def parameter
      [
        Parameter.new(:ivyfile, true),
        Parameter.new(:pomfile, true),
        Parameter.new(:templatefile, false),
        Parameter.new(:artifactName, false),
        Parameter.new(:artifactPackaging, false),
        Parameter.new(:conf, false),
        Parameter.new(:settingsRef, false),
        Parameter.new(:printIvyInfo, false),
        Parameter.new(:headerFile, false),
        Parameter.new(:description, false),
        Parameter.new(:nested, false)
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
