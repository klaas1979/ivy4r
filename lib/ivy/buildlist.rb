require 'ivy/target'

module Ivy
  class Buildlist < Ivy::Target
    def parameter
      [
        Parameter.new(:reference, false),
        Parameter.new(:nested, true),
        Parameter.new(:ivyfilepath, false),
        Parameter.new(:root, false),
        Parameter.new(:excluderoot, false),
        Parameter.new(:leaf, false),
        Parameter.new(:onlydirectdep, false),
        Parameter.new(:delimiter, false),
        Parameter.new(:excludeleaf, false),
        Parameter.new(:haltonerror, false),
        Parameter.new(:skipbuildwithoutivy, false),
        Parameter.new(:onMissingDescriptor, false),
        Parameter.new(:reverse, false),
        Parameter.new(:restartFrom, false),
        Parameter.new(:settingsRef, false)
      ]
    end

    protected
    def execute_ivy
      params[:reference] = "path-#{rand.to_s}" unless params[:reference]
      call_nested :ivy_buildlist => params
    end

    def create_return_values
      path = ant_references.find { |current| params[:reference] == current[0] }[1]
      raise "Could not get path for params #{params.inspect}" unless path && path.respond_to?(:list)
      path.list.map {|a| a.to_s }
    end
  end
end