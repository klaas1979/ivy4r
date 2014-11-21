# Extenions to the {Ruby-Java Bridge}[http://rjb.rubyforge.org/] module that
# add a generic Java object wrapper class for transparent access of java objects
# from ruby using RJB.
#
# This file was part of the Stanford Parser Ruby Wrapper by William Patrick McNeill.
# Only a few modifications have been done to make it compatible with ivy4r and the
# Java Ant objects that are accessed.
module Rjb
  class JavaObjectWrapper
    include Enumerable
    
    # The underlying Java object.
    attr_reader :java_object
    
    # Initialize with a Java object <em>obj</em>.  If <em>obj</em> is a
    # String, treat it as a Java class name and instantiate it.  Otherwise,
    # treat <em>obj</em> as an instance of a Java object.
    def initialize(obj, *args)
      @java_object = obj.class == String ? Rjb::import(obj).send(:new, *args) : obj
    end
    
    # Enumerate all the items in the object using its iterator.  If the object
    # has no iterator, this function yields nothing.
    def each
      if @java_object.getClass.getMethods.any? {|m| m.getName == "iterator"}
        i = @java_object.iterator
        while i.hasNext
          yield wrap_java_object(i.next)
        end
      end
    end # each
    
    # Reflect unhandled method calls to the underlying Java object and wrap
    # the return value in the appropriate Ruby object.
    def method_missing(m, *args)
      begin
        JavaObjectWrapper.wrap_java_object(@java_object.send(m, *args))
      rescue RuntimeError => e
        # The instance method failed.  See if this is a static method.
        if not e.message.match(/^Fail: unknown method name/).nil?
          getClass.send(m, *args)
        end
      end
    end
    
    # Checks if underlying java object responds to method prior using standard respond_to? method.
    def respond_to?(sym)
      java = @java_object.getClass.getMethods.any? {|m| m.getName == sym.to_s} || super.respond_to?(sym)
    end
    
    # Show the classname of the underlying Java object.
    def inspect
      "<#{@java_object._classname}>"
    end
    
    # Use the underlying Java object's stringification.
    def to_s
      toString
    end
    
    # All wrapping is done at class level and not at instance level this deviates from the base
    # implementation
    class << self
      # Convert a value returned by a call to the underlying Java object to the
      # appropriate Ruby object.
      #
      # If the value is a JavaObjectWrapper, convert it using a protected
      # function with the name wrap_ followed by the underlying object's
      # classname with the Java path delimiters converted to underscores. For
      # example, a <tt>java.util.ArrayList</tt> would be converted by a function
      # called wrap_java_util_ArrayList.
      #
      # If the value lacks the appropriate converter function, wrap it in a
      # generic JavaObjectWrapper.
      #
      # If the value is not a JavaObjectWrapper, return it unchanged.
      #
      # This function is called recursively for every element in an Array.
      def wrap_java_object(object)
        if object.kind_of?(Array)
          object.collect {|item| wrap_java_object(item)}
        elsif object.respond_to?(:_classname)
          # Ruby-Java Bridge Java objects all have a _classname member
          find_converter(object) || JavaObjectWrapper.new(object)
        else
          object
        end
      end
      
      protected
      # Checks if any class in objects class hierachy or interface of class has a converter method defined
      # if converter exists returns converted object.
      def find_converter(object)
        classnames_to_check(object).each do |name|
          wrapper = wrapper_name(name)
          if respond_to?(wrapper, true)
            return send(wrapper, object)
          end
        end
        
        nil
      end
      
      # Returns all java classnames that should be checked for an adequate mapper for given object.
      def classnames_to_check(object)
        names = []
        clazz = object.getClass
        while clazz
          names << clazz.getName
          clazz.getInterfaces.each {|i| names << i.getName}
          clazz = clazz.getSuperclass
        end
        
        names.uniq
      end
      
      # Returns the wrapper name for given java classname.
      def wrapper_name(java_classname)
        ("convert_" + java_classname.gsub(/\./, "_")).downcase.to_sym
      end
      
      # Convert <tt>java.util.List</tt> objects to Ruby Array objects.
      def convert_java_util_list(object)
        array_list = []
        object.size.times do
          |i| array_list << wrap_java_object(object.get(i))
        end
        array_list
      end
      
      # Convert <tt>java.util.Set</tt> objects to Ruby array object with no duplicates.
      def convert_java_util_set(object)
        set = []
        i = object.iterator
        while i.hasNext
          set << wrap_java_object(i.next)
        end
        set.uniq
      end
      
      # Convert <tt>java.util.Map</tt> objects to Ruby Hash object.
      def convert_java_util_map(object)
        hash = {}
        i = object.entrySet.iterator
        while i.hasNext
          entry = i.next
          hash[wrap_java_object(entry.getKey)] = wrap_java_object(entry.getValue)
        end
        hash
      end
      
      # Convert <tt>java.lang.String</tt> objects to Ruby String.
      def convert_java_lang_string(object)
        object.toString
      end
      
    end
  end
  
end
