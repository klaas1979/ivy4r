require 'facets'

module Ivy

  # Base class with general logic to call a Ivy ant target
  class Target
    attr_reader :params

    def initialize(ant)
      @ant = ant
    end

    # Executes this ivy target with given parameters returning a result.
    # __params__ can be a single Hash or an Array with or without a Hash as last value.
    # every value in array will be converted to string and set to __true__.
    # 
    # I.e. <tt>[:force, 'validate', {'name' => 'Blub'}]</tt>
    # results in parameters <tt>{'force'=>true, 'validate' => true, 'name'=>'Blub'}</tt>
    def execute(*params)
      @params = {}
      params.pop.each { |key, value| @params[key] = value } if Hash === params.last
      params.each { |key| @params[key.to_s] = true }

      validate
      before_hook
      execute_ivy
      create_return_values
    ensure
      after_hook
    end

    protected
    
    # Validates provided hash of parameters, raises an exception if any mandatory parameter is
    # missing or an unknown parameter has been provided.
    def validate
      unknown = params.keys - symbols(parameter)
      raise ArgumentError, "Unknown parameters '#{unknown.join(', ')}' for #{self.class}" unless unknown.empty?
      missing = symbols(mandatory_parameter).find_all { |p| params.keys.member?(p) == false }
      raise ArgumentError, "Missing mandatory parameters '#{missing.join(', ')}' for #{self.class}" unless missing.empty?
    end

    # Hook method called after validation but before #execute_ivy
    # overwrite for special actions needed
    def before_hook
    end

    # After hook is always called for #execute within +ensure+ block
    # overwrite for special clean up
    def after_hook
    end

    # Helper to call the nested ant targets recursively if nessecary. Must be called within +do+ +end+
    # block of ant target to work.
    def call_nested(nested)
      if nested
        nested.each do |method, paramlist|
          [paramlist].flatten.each do |params|
            if params.member? :nested
              p = params.dup
              nest = p.delete(:nested)
              @ant.send(method, p, &lambda {call_nested(nest)})
            else
              @ant.send(method, params)
            end
          end
        end
      end
    end

    # Creates the result for the execution by default it iterates of the ant properties and fetches
    # all properties that match the result properties for target as a hash. Overwrite to provide
    # a different result
    def create_return_values
      result_properties
    end
    
    # Fetches all result properties for called target and returns them as hash
    def result_properties
      result = ant_properties.map do |p|
        rp = result_property_values.find { |rp| rp.matcher === p[0] }
        rp ? [p[0], rp.parse(p[1])].flatten : nil
      end.compact.to_h(:multi)
      result.update_values do |v|
        case v.size
        when 0
          nil
        when 1
          v[0]
        else
          v
        end
      end

      result
    end

    def mandatory_parameter
      parameter.find_all {|p| p.mandatory? }
    end

    def symbols(params)
      params.map{|p| p.symbol}
    end
    
    def ant_properties
      @ant.project.properties
    end

    def ant_references
      @ant.project.references
    end
  end

    COMMA_SPLITTER = Proc.new {|value| value.to_s.split(',').map(&:strip)}

  Parameter = Struct.new(:symbol, :mandatory) do
    def mandatory?
      mandatory
    end
  end

  ResultValue = Struct.new(:matcher, :parser) do
    def parse(value)
      parser ? parser.call(value) : value
    end
  end
end
