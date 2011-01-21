require 'ivy4r'

class Rake::Application
  attr_accessor :ivy
end

module Rake
  module Ivy
    class IvyConfig
      
      # The directory to load ivy jars and its dependencies from, leave __nil__ to use default
      attr_accessor :lib_dir
      
      # The extension directory containing ivy settings, the local repository and cache
      attr_accessor :extension_dir
      
      # Returns the resolve result
      attr_reader :resolved
      
      attr_reader :post_resolve_tasks
      
      # Store the current rake application and initialize ivy ant wrapper
      def initialize(application)
        @application = application
        @extension_dir = File.join("#{@application.original_dir}", "#{ENV['IVY_EXT_DIR']}")
        @post_resolve_tasks = []
      end
      
      # Returns the correct ant instance to use.
      def ivy4r
        unless @ivy4r
          @ivy4r = ::Ivy4r.new do |i|
            i.cache_dir = result_cache_dir if caching_enabled?
          end
          @ivy4r.lib_dir = lib_dir if lib_dir
          @ivy4r.project_dir = @extension_dir
        end
        @ivy4r
      end
      
      # Returns if ivy result caching is enabled by existence of the marker file.
      def caching_enabled?
        File.exists? caching_marker
      end
      
      # Returns the use ivy result caching marker file
      def caching_marker
        File.expand_path 'use_ivy_caching'
      end
      
      # Returns the dir to store ivy caching results in.
      def result_cache_dir
        dir = File.expand_path('ivycaching')
        FileUtils.mkdir_p dir
        dir
      end
      
      # Returns the artifacts for given configurations as array
      # this is a post resolve task.
      # the arguments are checked for the following:
      # 1. if an Hash is given :conf is used for confs and :type is used for types
      # 2. if exactly two arrays are given args[0] is used for confs and args[1] is used for types
      # 3. if not exactly two arrays all args are used as confs
      def deps(*args)
        if args.size == 1 && args[0].kind_of?(Hash)
          confs, types = [args[0][:conf]].flatten, [args[0][:type]].flatten
        elsif args.size == 2 && args[0].kind_of?(Array) && args[1].kind_of?(Array)
          confs, types = args[0], args[1]
        else
          confs, types = args.flatten, []
        end
        
        [confs, types].each do |t|
          t.reject! {|c| c.nil? || c.empty? }
        end
        
        unless confs.empty?
          pathid = "ivy.deps." + confs.join('.') + '.' + types.join('.')
          params = {:conf => confs.join(','), :pathid => pathid}
          params[:type] = types.join(',') unless types.nil? || types.size == 0
          
          ivy4r.cachepath params
        end
      end
      
      # Returns ivy info for configured ivy file.
      def info
        ivy4r.settings :id => 'ivy.info.settingsref'
        ivy4r.info :file => file, :settingsRef => 'ivy.info.settingsref'
      end
      
      # Configures the ivy instance with additional properties and loading the settings file if it was provided
      def configure
        unless @configured
          ivy4r.property['ivy.status'] = status if status
          ivy4r.property['ivy.home'] = home if home
          properties.each {|key, value| ivy4r.property[key.to_s] = value }
          @configured = ivy4r.settings :file => settings if settings
        end
      end
      
      # Resolves the configured file once.
      def __resolve__
        unless @resolved
          @resolved = ivy4r.resolve :file => file
          post_resolve_tasks.each { |p| p.call(self) }
        end
        @resolved
      end
      
      # Creates the standard ivy dependency report
      def report
        ivy4r.report :todir => report_dir
      end
      
      # Publishs the project as defined in ivy file if it has not been published already
      def __publish__
        unless @published
          options = {:artifactspattern => "#{publish_from}/[artifact].[ext]"}
          options[:pubrevision] = revision if revision
          options[:status] = status if status
          options = publish_options * options
          ivy4r.publish options
          @published = true
        end
      end
      
      def home
        @ivy_home_dir
      end
      
      def settings
        @settings ||= "#{@extension_dir}/ivysettings.xml"
      end
      
      def file
        @ivy_file ||= 'ivy.xml'
      end
      
      # Sets the revision to use for the project, this is useful for development revisions that
      # have an appended timestamp or any other dynamic revisioning.
      #
      # To set a different revision this method can be used in different ways.
      # 1. project.ivy.revision(revision) to set the revision directly
      # 2. project.ivy.revision { |ivy| [calculate revision] } use the block for dynamic
      #    calculation of the revision. You can access ivy4r via <tt>ivy.ivy4r.[method]</tt>
      def revision(*revision, &block)
        raise "Invalid call with parameters and block!" if revision.size > 0 && block
        if revision.empty? && block.nil?
          if @revision_calc
            @revision ||= @revision_calc.call(self)
          else
            @revision
          end
        elsif block.nil?
          raise "revision value invalid #{revision.join(', ')}" unless revision.size == 1
          @revision = revision[0]
          self
        else
          @revision_calc = block
          self
        end
      end
      
      # Sets the status to use for the project, this is useful for custom status handling
      # like integration, alpha, gold.
      #
      # To set a different status this method can be used in different ways.
      # 1. project.ivy.status(status) to set the status directly
      # 2. project.ivy.status { |ivy| [calculate status] } use the block for dynamic
      #    calculation of the status. You can access ivy4r via <tt>ivy.ivy4r.[method]</tt>
      def status(*status, &block)
        raise "Invalid call with parameters and block!" if status.size > 0 && block
        if status.empty? && block.nil?
          if @status_calc
            @status ||= @status_calc.call(self)
          else
            @status
          end
        elsif status.empty? && block.nil?
          raise "status value invalid #{status.join(', ')}" unless status.size == 1
          @status = status[0]
          self
        else
          @status_calc = block
          self
        end
      end
      
      # Sets the publish options to use for the project. The options are merged with the default
      # options including value set via #publish_from and overwrite all of them.
      #
      # To set the options this method can be used in different ways.
      # 1. project.ivy.publish_options(options) to set the options directly
      # 2. project.ivy.publish_options { |ivy| [calculate options] } use the block for dynamic
      #    calculation of options. You can access ivy4r via <tt>ivy.ivy4r.[method]</tt>
      def publish_options(*options, &block)
        raise "Invalid call with parameters and block!" if options.size > 0 && block
        if options.empty? && block.nil?
          if @publish_options_calc
            @publish_options ||= @publish_options_calc.call(self)
          else
            @publish_options ||= {}
          end
        else
          if options.size > 0 && block.nil?
            raise "publish options value invalid #{options.join(', ')}" unless options.size == 1
            @publish_options = options[0]
            self
          else
            @publish_options_calc = block
            self
          end
        end
      end
      
      # Sets the additional properties for the ivy process use a Hash with the properties to set.
      def properties(*properties)
        if properties.empty?
          @properties ||= {}
        else
          raise "properties value invalid #{properties.join(', ')}" unless properties.size == 1
          @properties = properties[0]
          self
        end
      end
      
      # Sets the local repository for ivy files
      def local_repository(*local_repository)
        if local_repository.empty?
          @local_repository ||= "#{home}/repository"
        else
          raise "local_repository value invalid #{local_repository.join(', ')}" unless local_repository.size == 1
          @local_repository = local_repository[0]
          self
        end
      end
      
      # Sets the directory to publish artifacts from.
      def publish_from(*publish_dir)
        if publish_dir.empty?
          @publish_from ||= @application.original_dir
        else
          raise "publish_from value invalid #{publish_dir.join(', ')}" unless publish_dir.size == 1
          @publish_from = publish_dir[0]
          self
        end
      end
      
      # Sets the directory to create dependency reports in.
      def report_dir(*report_dir)
        if report_dir.empty?
          @report_dir ||= @application.original_dir
        else
          raise "publish_from value invalid #{report_dir.join(', ')}" unless report_dir.size == 1
          @report_dir = report_dir[0]
          self
        end
      end
    end
    
    # Adds given block as post resolve action that is executed directly after #resolve has been called.
    # Yields this ivy config object into block.
    # <tt>project.ivy.post_resolve { |ivy| p "all deps:" + ivy.deps('all').join(", ") }</tt>
    def post_resolve(&block)
      post_resolve_tasks << block if block
    end
    
    # Filter artifacts for given configuration with provided filter values, this is a post resolve
    # task like #deps.
    # <tt>project.ivy.filter('server', 'client', :include => /b.*.jar/, :exclude => [/a\.jar/, /other.*\.jar/])</tt>
    def filter(*confs)
      filter = confs.last.kind_of?(Hash) ? confs.pop : {}
      unless (filter.keys - (TYPES - [:conf])).empty?
        raise ArgumentError, "Invalid filter use :include and/or :exclude only: given #{filter.keys.inspect}"
      end
      includes, excludes, types = filter[:include] || [], filter[:exclude] || [], filter[:type] || []
      
      artifacts = deps(confs.flatten, types.flatten)
      if artifacts
        artifacts = artifacts.find_all do |lib|
          lib = File.basename(lib)
          includes = includes.reject {|i| i.nil? || (i.respond_to?(:empty?) && i.empty?) || (i.respond_to?(:source) && i.source.empty?) }
          should_include = includes.empty? || includes.any? {|include| include === lib }
          should_include && !excludes.any? {|exclude| exclude === lib}
        end
      end
      
      artifacts
    end
    
    class Tasks < ::Rake::TaskLib
      def initialize(ivy = nil, &block)
        @ivy = ivy || Rake::Ivy::IvyConfig.new(Rake.application)
        yield @ivy if block_given?
        Rake.application.ivy = @ivy
        
        define
      end
      
      private
      def define
        namespace 'ivy' do
          task :configure do
            Rake.application.ivy.configure
          end
          
          desc 'Resolves the ivy dependencies'
          task :resolve => "ivy:configure" do
            Rake.application.ivy.__resolve__
          end
          
          desc 'Publish the artifacts to ivy repository'
          task :publish => "ivy:resolve" do
            Rake.application.ivy.__publish__
          end
          
          desc 'Creates a dependency report for the project'
          task :report => "ivy:resolve" do
            Rake.application.ivy.report
          end
          
          desc 'Clean the local Ivy cache and the local ivy repository'
          task :clean do
            Rake.application.ivy.ivy4r.clean
          end
          
          desc 'Clean the local Ivy result cache to force execution of ivy targets'
          task :clean_result_cache do
            puts "Deleting IVY result cache dir '#{Rake.application.ivy.result_cache_dir}'"
            rm_rf Rake.application.ivy.result_cache_dir
          end
          
          desc 'Enable the local Ivy result cache by creating the marker file'
          task :enable_result_cache do
            puts "Creating IVY caching marker file '#{Rake.application.ivy.caching_marker}'"
            touch Rake.application.ivy.caching_marker
          end
          
          desc 'Disable the local Ivy result cache by removing the marker file'
          task :disable_result_cache do
            puts "Deleting IVY caching marker file '#{Rake.application.ivy.caching_marker}'"
            rm_f Rake.application.ivy.caching_marker
          end
        end
      end
    end
  end
end
