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

      # Store the current rake application and initialize ivy ant wrapper
      def initialize(application)
        @application = application
        @extension_dir = File.join("#{@application.original_dir}", "#{ENV['IVY_EXT_DIR']}")
      end

      # Returns the correct ant instance to use.
      def ant
        unless @ant
          @ant = ::Ivy4r.new
          @ant.lib_dir = lib_dir if lib_dir
          @ant.project_dir = @extension_dir
        end
        @ant
      end

      # Returns the artifacts for given configurations as array
      def deps(*confs)
        configure
        pathid = "ivy.deps." + confs.join('.')
        ant.cachepath :conf => confs.join(','), :pathid => pathid
      end

      # Returns ivy info for configured ivy file.
      def info
        ant.settings :id => 'ivy.info.settingsref'
        ant.info :file => file, :settingsRef => 'ivy.info.settingsref'
      end

      # Configures the ivy instance with additional properties and loading the settings file if it was provided
      def configure
        unless @configured
          ant.property['ivy.status'] = status
          ant.property['ivy.home'] = home
          properties.each {|key, value| ant.property[key.to_s] = value }
          @configured = ant.settings :file => settings if settings
        end
      end

      # Resolves the configured file once.
      def resolve
        unless @resolved
          @resolved = ant.resolve :file => file
        end
      end

      # Creates the standard ivy dependency report
      def report
        ant.report :todir => report_dir
      end

      # Publishs the project as defined in ivy file if it has not been published already
      def publish
        unless @published
          options = {:artifactspattern => "#{publish_from}/[artifact].[ext]"}
          options[:pubrevision] = revision if revision
          options[:status] = status if status
          options = publish_options * options
          ant.publish options
          @published = true
        end
      end

      def home
        @ivy_home_dir ||= "#{@extension_dir}/ivy-home"
      end

      def settings
        @settings ||= "#{@extension_dir}/ant-scripts/ivysettings.xml"
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
      #    calculation of the revision. You can access ivy4r via <tt>ivy.ant.[method]</tt>
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
      #    calculation of the status. You can access ivy4r via <tt>ivy.ant.[method]</tt>
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
      #    calculation of options. You can access ivy4r via <tt>ivy.ant.[method]</tt>
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
            Rake.application.ivy.resolve
          end

          desc 'Publish the artifacts to ivy repository'
          task :publish => "ivy:resolve" do
            Rake.application.ivy.publish
          end

          desc 'Creates a dependency report for the project'
          task :report => "ivy:resolve" do
            Rake.application.ivy.report
          end

          desc 'Clean the local Ivy cache and the local ivy repository'
          task :clean do
            Rake.application.ivy.ant.clean
          end
        end
      end
    end
  end
end
