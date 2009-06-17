require 'ivy/target'

module Ivy
  class Cachepath < Ivy::Target
    def parameter
      [
        Parameter.new(:pathid, true),
        Parameter.new(:conf, false),
        Parameter.new(:inline, false),
        Parameter.new(:organisation, false),
        Parameter.new(:module, false),
        Parameter.new(:revision, false),
        Parameter.new(:branch, false),
        Parameter.new(:type, false),
        Parameter.new(:settingsRef, false),
      ]
    end

    def create_return_values
      path = ant_references.find { |current| current[0] == params[:pathid] }[1]
      raise "Could not get path for confs: #{params.inspect}" unless path && path.respond_to?(:list)
      path.list.map {|a| a.to_s }
    end

    protected
    def execute_ivy
      call_nested :ivy_cachepath => params
    end
  end
end