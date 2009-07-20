require 'ivy4r'

module Buildr
  module Ivy

    # TODO extend extension to download ivy stuff with dependencies automatically
    #    VERSION = '2.1.0-rc1'

    class << self

      def setting(*keys)
        setting = Buildr.settings.build['ivy']
        keys.each { |key| setting = setting[key] unless setting.nil? }
        setting
      end

      #      def version
      #        setting['version'] || VERSION
      #      end
      #      def dependencies
      #        @dependencies ||= [
      #          "org.apache.ivy:ivy:jar:#{version}",
      #          'com.jcraft:jsch:jar:1.41',
      #          'oro:oro:jar:2.08'
      #        ]
      #      end
    end
    
    class IvyConfig

      attr_accessor :extension_dir, :resolved

      # Store the current project and initialize ivy ant wrapper
      def initialize(project)
        @project = project
        if project.parent.nil?
          @extension_dir = @project.base_dir
        else
          @extension_dir = @project.parent.ivy.extension_dir
          @base_ivy = @project.parent.ivy unless own_file?
        end
      end
      
      def enabled?
        @enabled ||= Ivy.setting('enabled') || true
      end

      def own_file?
        @own_file ||= File.exists?(@project.path_to(file))
      end

      # Returns the correct ant instance to use, if project has its own ivy file uses the ivy file
      # of project, if not uses the ivy file of parent project.
      def ant
        unless @ant
          if own_file?
            @ant = ::Ivy4r.new(@project.ant('ivy'))
            @ant.lib_dir = lib_dir if lib_dir
            @ant.project_dir = @extension_dir
          else
            @ant = @project.parent.ivy.ant
          end
        end
        @ant
      end

      # Returns name of the project the ivy file belongs to.
      def file_project
        own_file? ? @project : @base_ivy.file_project
      end

      # Returns the artifacts for given configurations as array
      def deps(*confs)
        configure
        confs = confs.reject {|c| c.nil? || c.blank? }
        unless confs.empty?
          pathid = "ivy.deps." + confs.join('.')
          ant.cachepath :conf => confs.join(','), :pathid => pathid
        end
      end

      # Returns ivy info for configured ivy file using a new ant instance.
      def info
        if @base_ivy
          @base_ivy.info
        else
          ant.settings :id => 'ivy.info.settingsref'
          result = ant.info :file => file, :settingsRef => 'ivy.info.settingsref'
          @ant = nil
          result
        end
      end

      # Configures the ivy instance with additional properties and loading the settings file if it was provided
      def configure
        if @base_ivy
          @base_ivy.configure
        else
          unless @configured
            ant.property['ivy.status'] = status
            ant.property['ivy.home'] = home
            properties.each {|key, value| ant.property[key.to_s] = value }
            @configured = ant.settings :file => settings if settings
          end
        end
      end

      # Resolves the configured file once.
      def resolve
        if @base_ivy
          @base_ivy.resolve
        else
          unless @resolved
            @resolved = ant.resolve :file => file
          end
        end
      end

      # Returns the additional infos for the manifest file.
      def manifest
        if @base_ivy
          @base_ivy.manifest
        else
          {
            'organisation' => @resolved['ivy.organisation'],
            'module' => @resolved['ivy.organisation'],
            'revision' => revision
          }
        end
      end

      # Creates the standard ivy dependency report
      def report
        ant.report :todir => report_dir
      end

      # Publishs the project as defined in ivy file if it has not been published already
      def publish
        if @base_ivy
          @base_ivy.publish
        else
          unless @published
            options = {:status => status, :pubrevision => revision, :artifactspattern => "#{publish_from}/[artifact].[ext]"}
            options = publish_options * options
            ant.publish options
            @published = true
          end
        end
      end

      def home
        @ivy_home_dir ||= Ivy.setting('home.dir') || "#{@extension_dir}/ivy-home"
      end

      def lib_dir
        @lib_dir ||= Ivy.setting('lib.dir')
      end
      
      def settings
        @settings ||= Ivy.setting('settings.file') || "#{@extension_dir}/ant-scripts/ivysettings.xml"
      end

      def file
        @ivy_file ||= Ivy.setting('ivy.file') || 'ivy.xml'
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
            @revision ||= @project.version
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
            @status ||= Ivy.setting('status') || 'integration'
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
            @publish_options ||= Ivy.setting('publish.options')
          end
        else
          raise "Could not set 'publish_options' for '#{@project.name}' without own ivy file!" unless own_file?
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
          if own_file?
            @local_repository ||= Ivy.setting('local.repository.dir') || "#{home}/repository"
          else
            @project.parent.ivy.local_repository
          end
        else
          raise "Could not set 'local_repository' for '#{@project.name}' without own ivy file!" unless own_file?
          raise "local_repository value invalid #{local_repository.join(', ')}" unless local_repository.size == 1
          @local_repository = local_repository[0]
          self
        end
      end

      # Maps a package to a different name for publishing. This name is used instead of the default name
      # for publishing use a hash with the +package+ as key and the newly mapped name as value. I.e.
      # <tt>ivy.name(package(:jar) => 'new_name_without_version_number.jar')</tt>
      # Note that this method is additive, a second call adds the names to the first.
      def name(*name_mappings)
        if name_mappings.empty?
          @name_mappings ||= {}
        else
          raise "name_mappings value invalid #{name_mappings.join(', ')}" unless name_mappings.size == 1
          @name_mappings = @name_mappings ? @name_mappings + name_mappings[0] : name_mappings[0].dup
          self
        end
      end

      # Sets the directory to publish artifacts from.
      def publish_from(*publish_dir)
        if publish_dir.empty?
          if own_file?
            @publish_from ||= Ivy.setting('publish.from') || @project.path_to(:target)
          else
            @project.parent.ivy.publish_from
          end
        else
          raise "Could not set 'publish_from' for '#{@project.name}' without own ivy file!" unless own_file?
          raise "publish_from value invalid #{publish_dir.join(', ')}" unless publish_dir.size == 1
          @publish_from = publish_dir[0]
          self
        end
      end

      # Sets the directory to create dependency reports in.
      def report_dir(*report_dir)
        if report_dir.empty?
          if own_file?
            @report_dir ||= Ivy.setting('report.dir') || @project.path_to(:reports, 'ivy')
          else
            @project.parent.ivy.report_dir
          end
        else
          raise "Could not set 'report_dir' for '#{@project.name}' without own ivy file!" unless own_file?
          raise "publish_from value invalid #{report_dir.join(', ')}" unless report_dir.size == 1
          @report_dir = report_dir[0]
          self
        end
      end

      # Sets the includes pattern(s) to use for compile, test and package, via the equivalent symbols. I.e.
      # <tt>project.ivy.include(:compile => [/\.jar/, /\.gz/], :package => 'cglib.jar')</tt>
      def include(includes)
        includes.each do |type, value|
          handle_variable(type, :include, *value)
        end
        self
      end

      # Sets the exclude pattern(s) to use for compile, test and package, via the equivalent symbols. I.e.
      # <tt>project.ivy.exclude(:compile => [/\.jar/, /\.gz/], :package => 'cglib.jar')</tt>
      def exclude(excludes)
        excludes.each do |type, value|
          handle_variable(type, :exclude, *value)
        end
        self
      end

      # Sets the conf to use for compile, test and package, via the equivalent symbols. I.e.
      # <tt>project.ivy.conf(:compile => ['base', 'server'], :package => 'prod')</tt>
      def conf(confs)
        confs.each do |type, value|
          handle_variable(type, :conf, *value)
        end
        self
      end

      # Set the artifacts to include into compile. See #include to set this via hash.
      def compile_include(*includes)
        handle_variable(:compile, :include, *includes)
      end

      # Set the artifacts to exclude into compile. See #exclude to set this via hash.
      def compile_exclude(*includes)
        handle_variable(:compile, :exclude, *includes)
      end

      # Set the artifacts to include into test. See #include to set this via hash.
      def test_include(*includes)
        handle_variable(:test, :include, *includes)
      end

      # Set the artifacts to exclude into test. See #exclude to set this via hash.
      def test_exclude(*includes)
        handle_variable(:test, :exclude, *includes)
      end

      # Set the artifacts to include into package. See #include to set this via hash.
      def package_include(*includes)
        handle_variable(:package, :include, *includes)
      end

      # Set the artifacts to exclude into package. See #exclude to set this via hash.
      def package_exclude(*includes)
        handle_variable(:package, :exclude, *includes)
      end

      # Set the configuration artifacts to use for compile tasks, added to <tt>compile.with</tt>
      # <tt>project.ivy.compile_conf('server', 'client')</tt>
      # See #conf to do this via hash.
      def compile_conf(*compile_conf)
        handle_variable(:compile, :conf, *compile_conf)
      end

      # Set the configuration artifacts to use for test tasks, added to <tt>test.compile.with</tt>
      # and <tt>test.with</tt>. Note that all artifacts from #compile_conf are added automatically.
      # <tt>project.ivy.test_conf('server', 'test')</tt>
      # See #conf to do this via hash.
      def test_conf(*test_conf)
        handle_variable(:test, :conf, *test_conf)
      end

      # Set the configuration artifacts to use in package tasks like +:war+ or +:ear+.
      # <tt>project.ivy.package_conf('server', 'client')</tt>
      # or
      # <tt>project.ivy.package_conf(['server', 'client'])</tt>
      # See #conf to do this via hash.
      def package_conf(*package_conf)
        handle_variable(:package, :conf, *package_conf)
      end

      # Helper to return all artifacts for given confs filtered after includes and excludes.
      def filter(confs, includes, excludes)
        artifacts = deps(*confs)
        if artifacts
          artifacts = artifacts.find_all do |lib|
            lib = File.basename(lib)
            includes = includes.reject {|i| i.nil? || i.blank? }
            should_include = includes.empty? || includes.any? {|include| include === lib }
            should_include && !excludes.any? {|exclude| exclude === lib}
          end
        end

        artifacts
      end

      private
      # Sets a variable for given basename and type to given values. If values are empty returns the
      # current value.
      # I.e. <tt>handle_variable(:package, :include, /blua.*\.jar/, /da.*\.jar/)</tt>
      def handle_variable(basename, type, *values)
        variable = "@#{basename.to_s}_#{type.to_s}".to_sym
        unless [:@compile_conf, :@test_conf, :@package_conf, :@compile_include, :@test_include,
            :@package_include, :@compile_exclude, :@test_exclude, :@package_exclude].member?(variable)
          raise ArgumentError, "Unknown variable '#{variable.to_s}' for basename '#{basename.to_s}' and type '#{type.to_s}'"
        end
        if values.empty?
          variable_value = instance_variable_get(variable)
          instance_variable_set(variable, [Ivy.setting("#{basename.to_s}.#{type.to_s}") || ''].flatten.uniq) unless variable_value
          instance_variable_get(variable)
        else
          instance_variable_set(variable, [values].flatten.uniq)
          self
        end
      end
    end

=begin rdoc
The Ivy Buildr extension adding the new tasks for ivy.

To use ivy in a +buildfile+ do something like:
  ENV['BUILDR_EXT_DIR'] ||= '../Ivy'
  require 'buildr/ivy_extension'
    define 'ivy_project' do
    [...]
    ivy.compile_conf('compile').test_conf('test').package_conf('prod', 'server')
    [...]
  end

- This will add the +compile+ configuration to compile and test tasks
- Add the +test+ configuration to test compilation and execution
- include the artifacts from +prod+ and +server+ to any generated war or ear
- The ENV variable is needed to automatically configure the load path for ivy libs.
  It assumes that you have the following dir structure <tt>[BUILDR_EXT_DIR]/ivy-home/jars</tt>

For more configuration options see IvyConfig.
=end
    module IvyExtension
      include Buildr::Extension

      class << self
        def add_ivy_deps_to_java_tasks(project)
          resolve_target = project.ivy.file_project.task('ivy:resolve')
          project.task :compiledeps => resolve_target do
            includes = project.ivy.compile_include
            excludes = project.ivy.compile_exclude
            confs = [project.ivy.compile_conf].flatten
            project.compile.with project.ivy.filter(confs, includes, excludes)
            info "Ivy adding compile dependencies '#{confs.join(', ')}' to project '#{project.name}'"
          end
          
          project.task :compile => "#{project.name}:compiledeps"

          project.task :testdeps => resolve_target do
            includes = project.ivy.test_include
            excludes = project.ivy.test_exclude
            confs = [project.ivy.test_conf, project.ivy.compile_conf].flatten.uniq
            project.test.with project.ivy.filter(confs, includes, excludes)
            info "Ivy adding test dependencies '#{confs.join(', ')}' to project '#{project.name}'"
          end
          project.task "test:compile" => "#{project.name}:testdeps"

          project.task :javadocdeps => resolve_target do
            confs = [project.ivy.test_conf, project.ivy.compile_conf].flatten.uniq
            project.javadoc.with project.ivy.deps(confs)
            info "Ivy adding javadoc dependencies '#{confs.join(', ')}' to project '#{project.name}'"
          end
          project.task :javadoc => "#{project.name}:javadocdeps"

          [project.task(:eclipse), project.task(:idea), project.task(:idea7x)].each do |task|
            task.prerequisites.each{|p| p.enhance ["#{project.name}:compiledeps", "#{project.name}:testdeps"]}
          end
        end

        def add_manifest_to_distributeables(project)
          pkgs = project.packages.find_all { |pkg| [:jar, :war, :ear].member? pkg.type }
          pkgs.each do |pkg|
            name = "#{pkg.name}manifest"
            task = project.task name => project.ivy.file_project.task('ivy:resolve') do
              pkg.with :manifest => project.manifest.merge(project.ivy.manifest)
              info "Adding manifest entries to package '#{pkg.name}'"
            end
            project.task :build => task
          end
        end

        def add_prod_libs_to_distributeables(project)
          pkgs = project.packages.find_all { |pkg| [:war, :ear].member? pkg.type }
          pkgs.each do |pkg|
            name = "#{pkg.name}deps"
            task = project.task name => project.ivy.file_project.task('ivy:resolve') do
              includes = project.ivy.package_include
              excludes = project.ivy.package_exclude
              confs = project.ivy.package_conf
              pkg.with :libs => project.ivy.filter(confs, includes, excludes)
              info "Adding production libs from conf '#{confs.join(', ')}' to package '#{pkg.name}' in project '#{project.name}'"
            end
            project.task :build => task
          end
        end

        def add_copy_tasks_for_publish(project)
          if project.ivy.own_file?
            Buildr.projects.each do |current|
              current.packages.each do |pkg|
                target_file = current.ivy.name[pkg] || File.basename(pkg.name).gsub(/-#{project.version}/, '')
                taskname = current.path_to(project.ivy.publish_from, target_file)
                if taskname != pkg.name
                  project.file taskname => pkg.name do
                    verbose "Ivy copying '#{pkg.name}' to '#{taskname}' for publishing"
                    FileUtils.mkdir File.dirname(taskname) unless File.directory?(File.dirname(taskname))
                    FileUtils.cp pkg.name, taskname
                  end
                end
                project.task 'ivy:publish' => taskname
              end
            end
          end
        end
      end

      # Returns the +ivy+ configuration for the project. Use this to configure Ivy.
      # see IvyConfig for more details about configuration options.
      def ivy
        @ivy_config ||= IvyConfig.new(self)
      end

      first_time do
        namespace 'ivy' do
          desc 'Resolves the ivy dependencies'
          task :resolve

          desc 'Publish the artifacts to ivy repository as defined by environment'
          task :publish

          desc 'Creates a dependency report for the project'
          task :report
      
          desc 'Clean the local Ivy cache and the local ivy repository'
          task :clean
        end
      end

      before_define do |project|
        if project.parent.nil? && project.ivy.enabled?
          info = project.ivy.info
          project.version = info['ivy.revision']
          project.group = "#{info['ivy.organisation']}.#{info['ivy.module']}"
        end
      end

      after_define do |project|
        if project.ivy.enabled?
          IvyExtension.add_ivy_deps_to_java_tasks(project)
          IvyExtension.add_manifest_to_distributeables(project)
          IvyExtension.add_prod_libs_to_distributeables(project)
          IvyExtension.add_copy_tasks_for_publish(project)

          task :clean do
            # TODO This is redundant, refactor ivy_ant_wrap and this to use a single config object
            info "Cleaning ivy reports"
            rm_rf project.path_to(:reports, 'ivy')
          end

          namespace 'ivy' do
            task :configure do
              project.ivy.configure
            end

            task :resolve => "#{project.name}:ivy:configure" do
              project.ivy.resolve
            end

            task :report => "#{project.name}:ivy:resolve" do
              project.ivy.report
            end

            task :publish => "#{project.name}:ivy:resolve" do
              project.ivy.publish
            end
          end
        end
      end
    end

    # Global targets that are not bound to a project
    namespace 'ivy' do
      task :clean do
        info "Cleaning local ivy cache"
        Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
          project.ivy.ant.clean
        end
      end

      task :resolve do
        info "Resolving all distinct ivy files"
        Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
          project.task('ivy:resolve').invoke
        end
      end
      
      task :publish => :package do
        info "Publishing all distinct ivy files"
        Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
          project.task('ivy:publish').invoke
        end
      end
    end

    class Buildr::Project # :nodoc:
      include IvyExtension
    end
  end
end
