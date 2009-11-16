require 'ivy/target'

module Ivy
  class ToIvyFile < Ivy::Target
    def parameter
      [
        Parameter.new(:file, true),
        Parameter.new(:overwrite, false)
      ]
    end

    protected
    def execute_ivy
      descriptor = ant_references.find {|tuple| tuple[0] == 'ivy.resolved.descriptor'}
      raise 'to_ivy_file is a post resolve task but no resolved descriptor was found!' if descriptor.nil?
      descriptor = descriptor[1]
      
      file = params[:file]
      overwrite = params[:overwrite] && params[:overwrite].to_s == 'true'
      unless !File.exists?(file) || overwrite
        raise "Output file '#{file}' exists and ':overwrite' is false or unset: #{params[:overwrite]}"
      end
      
      descriptor.toIvyFile(java.io.File.new(file))
    end

    def create_return_values
      nil
    end
  end
end