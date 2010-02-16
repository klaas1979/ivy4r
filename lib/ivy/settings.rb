require 'ivy/configure'

module Ivy
  class Settings < Ivy::Configure

    def create_return_values
      nil
    end

    protected
    def execute_ivy
      call_nested :ivy_settings => params
    end
  end
end
