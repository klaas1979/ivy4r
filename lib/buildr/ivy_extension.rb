require 'ivy4r'

module Buildr
  module Ivy
    
    class << self
      def setting(*keys)
        find_setting(Buildr.settings.build['ivy'], *keys)
      end
      
      def user_setting(*keys)
        find_setting(Buildr.settings.user['ivy'], *keys)
      end
      
      private
      def find_setting(setting, *keys)
        keys.each { |key| setting = setting[key] unless setting.nil? }
        setting
      end
    end
    
    class IvyConfig
      TARGETS = [:compile, :test, :package]
      TYPES = [:conf, :type, :include, :exclude]
      
      attr_accessor :extension_dir, :resolved
      
      attr_reader :post_resolve_task_list
      
      attr_reader :project
      
      # Hash of all artifacts to publish with mapping from artifact name to ivy publish name
      attr_reader :publish_mappings
      
      # Store the current project and initialize ivy ant wrapper
      def initialize(project)
        @project = project
        @post_resolve_task_list = []
        @extension_dir = project.parent.nil? ? @project.base_dir : @project.parent.ivy.extension_dir
        @base_ivy = @project.parent.ivy unless own_file? 
        @target_config = Hash.new do
          |hash, key| hash[key] = {}
        end
        
      end
      
      def enabled?
        setting = Ivy.setting('enabled')
        @enabled ||= setting.nil? ? true : setting
      end
      
      def own_file?
        @own_file ||= File.exists?(file)
      end
      
      # Returns the correct ivy4r instance to use, if project has its own ivy file uses the ivy file
      # of project, if not uses the ivy file of parent project.
      # Use this for low-level access to ivy functions as needed, i.e. in +post_resolve+
      def ivy4r
        unless @ivy4r
          if own_file?
            @ivy4r = ::Ivy4r.new do |i|
              i.ant = @project.ant('ivy')
              if caching_enabled?
                i.cache_dir = result_cache_dir
                @project.send(:info, "Using IVY result caching in dir '#{i.cache_dir}'")
              end
            end
            @ivy4r.lib_dir = lib_dir if lib_dir
            @ivy4r.project_dir = @extension_dir
          else
            @ivy4r = @project.parent.ivy.ivy4r
          end
        end
        @ivy4r
      end
      
      # Returns if ivy result caching is enabled via build or user properties or by existence of the
      # marker file.
      def caching_enabled?
        Ivy.user_setting('caching.enabled') || Ivy.setting('caching.enabled') || File.exists?(caching_marker)
      end
      
      # Returns the use ivy result caching marker file
      def caching_marker
        @project.path_to('use_ivy_caching')
      end
      
      # Returns the dir to store ivy caching results in.
      def result_cache_dir
        dir = @project.path_to('target', 'ivycaching')
        FileUtils.mkdir_p dir
        dir
      end
      
      # Returns name of the project the ivy file belongs to.
      def file_project
        own_file? ? @project : @base_ivy.file_project
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
          t.reject! {|c| c.nil? || c.blank? }
        end
        
        unless confs.empty?
          pathid = "ivy.deps." + confs.join('.') + '.' + types.join('.')
          params = {:conf => confs.join(','), :pathid => pathid}
          params[:type] = types.join(',') unless types.nil? || types.size == 0
          
          ivy4r.cachepath params
        end
      end
      
      # Returns ivy info for configured ivy file using a new ivy4r instance.
      def info
        if @base_ivy
          @base_ivy.info
        else
          ivy4r.settings :id => 'ivy.info.settingsref'
          result = ivy4r.info :file => file, :settingsRef => 'ivy.info.settingsref'
          @ivy4r = nil
          result
        end
      end
      
      # Configures the ivy instance with additional properties and loading the settings file if it was provided
      def configure
        if @base_ivy
          @base_ivy.configure
        else
          unless @configured
            ivy4r.property['ivy.status'] = status
            ivy4r.property['ivy.home'] = home
            properties.each {|key, value| ivy4r.property[key.to_s] = value }
            @configured = ivy4r.settings :file => settings if settings
          end
        end
      end
      
      # Resolves the configured file once.
      def __resolve__
        if @base_ivy
          @base_ivy.__resolve__
        else
          unless @resolved
            @resolved = ivy4r.resolve :file => file
            @project.send(:info, "Calling '#{post_resolve_tasks.size}' post_resolve tasks for '#{@project.name}'")
            post_resolve_tasks.each { |p| p.call(self) }
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
        ivy4r.report :todir => report_dir
      end
      
      # Cleans the ivy cache
      def cleancache
        ivy4r.cleancache
      end
      
      
      # Publishs the project as defined in ivy file if it has not been published already
      def __publish__
        if @base_ivy
          @base_ivy.__publish__
        else
          unless @published
            options = {:status => status, :pubrevision => revision, :artifactspattern => "#{publish_from}/[artifact].[ext]"}
            options = publish_options * options
            ivy4r.publish options
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
      
      # The basic file name to use in project dir as ivy.xml file. Normally this should be __ivy.xml__
      # If the file resides in a sub directory the relative path from project can be set with this method
      def ivy_xml_filename
        @ivy_file ||= Ivy.setting('ivy.file') || 'ivy.xml'
      end
      
      # Returns the absolute ivy file path to use
      def file
        @project.path_to(ivy_xml_filename)
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
      #    calculation of the status. You can access ivy4r via <tt>ivy.ivy4r.[method]</tt>
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
      #    calculation of options. You can access ivy4r via <tt>ivy.ivy4r.[method]</tt>
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
      
      # :call-seq:
      # ivy.publish(package(:jar) => 'new_name_without_version_number.jar')
      # #deprecated! ivy.name(package(:jar) => 'new_name_without_version_number.jar')
      #
      # Maps a package to a different name for publishing. This name is used instead of the default name
      # for publishing use a hash with the +package+ as key and the newly mapped name as value. I.e.
      # <tt>ivy.name(package(:jar) => 'new_name_without_version_number.jar')</tt>
      # Note that this method is additive, a second call adds the names to the first.
      def publish(*publish_mappings)
        if publish_mappings.empty?
          @publish_mappings ||= {}
        else
          raise "publish_mappings value invalid #{publish_mappings.join(', ')}" unless publish_mappings.size == 1
          @publish_mappings = @publish_mappings ? @publish_mappings + publish_mappings[0] : publish_mappings[0].dup
          self
        end
      end
      
      def name(*args)
        puts "name(*args) is deprecated use publish(*args)!"
        publish(*args)
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
            includes = includes.reject {|i| i.nil? || i.blank? }
            should_include = includes.empty? || includes.any? {|include| include === lib }
            should_include && !excludes.any? {|exclude| exclude === lib}
          end
        end
        
        artifacts
      end
      
      # :call-seq:
      # for types:
      #   project.ivy.include(:compile => [/\.jar/, /\.gz/], :package => 'cglib.jar')
      #   project.ivy.exclude(:test => 'cglib.jar')
      #   project.ivy.conf(:compile => 'compile', :test => 'test', :package => 'prod')
      # for targets:
      #   project.ivy.compile(:conf => 'compile', :exclude => /cglib.jar/)
      #   project.ivy.test(:conf => 'test')
      #   project.ivy.package(:conf => 'prod', :include => /.*.jar/, :exclude => /cglib.jar/)
      # or verbose:
      #   project.ivy.compile_conf or project.ivy.conf_compile
      #   project.ivy.compile_include or project.ivy.include_compile
      # the same for the other possible options.
      #
      # Uses #method_missing to handle the options.
      # Generic handling of settings for +target+ and +type+. All calls in the form
      # <tt>target_type({})</tt> or <tt>type_target({})</tt> are handled via this method see
      # #TARGETS #TYPES for more information about valid targets and types.
      def method_missing(methodname, *args, &block)
        if block.nil? && valid_config_call?(methodname)
          target, type = target(methodname), type(methodname)
          if target && type
            handle_variable(target, type, *args)
          elsif target && args.size == 1 && args.last.kind_of?(Hash)
            args[0].each { |type, value| handle_variable(target, type, *value) }
            self
          elsif type && args.size == 1 && args.last.kind_of?(Hash)
            args[0].each { |target, value| handle_variable(target, type, *value) }
            self
          else
            raise "Could not recognize config call for method '#{methodname}', args=#{args.inspect}"
          end
        else
          super.method_missing(methodname, *args, &block)
        end
      end
      
      private
      def target(targets)
        t = targets.to_s.split('_').find { |target| TARGETS.member? target.to_sym }
        t ? t.to_sym : nil
      end
      
      def type(types)
        t = types.to_s.split('_').find { |type| TYPES.member? type.to_sym }
        t ? t.to_sym : nil
      end
      
      def valid_config_call?(method_name)
        valid_calls = []
        TYPES.each do|type|
        TARGETS.each do|target|
        valid_calls << type.to_s << target.to_s << "#{type}_#{target}" << "#{target}_#{type}"
      end
    end
    valid_calls.member? method_name.to_s
  end
  
  # Sets a variable for given basename and type to given values. If values are empty returns the
  # current value.
  # I.e. <tt>handle_variable(:package, :include, /blua.*\.jar/, /da.*\.jar/)</tt>
  def handle_variable(target, type, *values)
    unless TARGETS.member?(target) && TYPES.member?(type)
      raise ArgumentError, "Unknown config value for target #{target.inspect} and type #{type.inspect}"
    end
    if values.empty?
      @target_config[target][type] ||= [Ivy.setting("#{target.to_s}.#{type.to_s}") || ''].flatten.uniq
    else
      @target_config[target][type] = [values].flatten.uniq
      self
    end
  end
  
  def post_resolve_tasks
    @base_ivy ? @base_ivy.post_resolve_task_list : post_resolve_task_list
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
        types = project.ivy.compile_type
        confs = [project.ivy.compile_conf].flatten
        if deps = project.ivy.filter(confs, :type => types, :include => includes, :exclude => excludes)
          project.compile.with [deps, project.compile.dependencies].flatten
          sort_dependencies(project.compile.dependencies, deps, project.path_to(''))
          info "Ivy adding compile dependencies '#{confs.join(', ')}' to project '#{project.name}'"
        end
      end
      
      project.task :compile => "#{project.name}:compiledeps"
      
      project.task :testdeps => resolve_target do
        includes = project.ivy.test_include
        excludes = project.ivy.test_exclude
        types = project.ivy.test_type
        confs = [project.ivy.test_conf, project.ivy.compile_conf].flatten.uniq
        if deps = project.ivy.filter(confs, :type => types, :include => includes, :exclude => excludes)
          project.test.with [deps, project.test.dependencies].flatten
          sort_dependencies(project.test.dependencies, deps, project.path_to(''))
          sort_dependencies(project.test.compile.dependencies, deps, project.path_to(''))
          info "Ivy adding test dependencies '#{confs.join(', ')}' to project '#{project.name}'"
        end
      end
      project.task "test:compile" => "#{project.name}:testdeps"
      
      project.task :javadocdeps => resolve_target do
        confs = [project.ivy.test_conf, project.ivy.compile_conf].flatten.uniq
        if deps = project.ivy.deps(confs)
          project.javadoc.with deps
          info "Ivy adding javadoc dependencies '#{confs.join(', ')}' to project '#{project.name}'"
        end
      end
      project.task :javadoc => "#{project.name}:javadocdeps"
      
      [project.task(:eclipse), project.task(:idea), project.task(:idea7x)].each do |task|
        task.prerequisites.each{|p| p.enhance ["#{project.name}:compiledeps", "#{project.name}:testdeps"]}
      end
    end
    
    # Sorts the dependencies in #deps replacing the old order.
    # Sorting is done as follows:
    # 1. all dependencies that belong to the project identified by #project_path,
    #    .i.e. instrumented-classes, resources in the order the are contained in the array
    # 2. all ivy dependencies identified by #ivy_deps
    # 3. all dependencies added automatically by buildr
    def sort_dependencies(deps, ivy_deps, project_path)
      old_deps = deps.dup
      belongs_to_project = /#{project_path}/
      deps.sort! do |a, b|
        a_belongs_to_project = belongs_to_project.match(a.to_s)
        b_belongs_to_project = belongs_to_project.match(b.to_s)
        a_ivy = ivy_deps.member? a
        b_ivy = ivy_deps.member? b
        
        if a_belongs_to_project && !b_belongs_to_project
          -1
        elsif !a_belongs_to_project && b_belongs_to_project
          1
        elsif a_ivy && !b_ivy
          -1
        elsif !a_ivy && b_ivy
          1
        else
          old_deps.index(a) <=> old_deps.index(b)
        end
      end
    end
    
    def add_manifest_to_distributeables(project)
      pkgs = project.packages.find_all { |pkg| ['jar', 'war', 'ear'].member? pkg.type.to_s }
      pkgs.each do |pkg|
        name = "#{pkg.name}manifest"
        task = project.task name => project.ivy.file_project.task('ivy:resolve') do
          pkg.with :manifest => pkg.manifest.merge(project.manifest.merge(project.ivy.manifest))
          info "Adding manifest entries to package '#{pkg.name}'"
        end
        project.task :build => task
      end
    end
    
    def add_prod_libs_to_distributeables(project)
      pkgs = project.packages.find_all { |pkg| ['war'].member? pkg.type.to_s }
      pkgs.each do |pkg|
        task = project.task "#{pkg.name}deps" => project.ivy.file_project.task('ivy:resolve') do
          includes = project.ivy.package_include
          excludes = project.ivy.package_exclude
          types = project.ivy.package_type
          confs = project.ivy.package_conf
          if deps = project.ivy.filter(confs, :type => types, :include => includes, :exclude => excludes)
            pkg.with :libs => [deps, pkg.libs].flatten
            info "Adding production libs from conf '#{confs.join(', ')}' to WAR '#{pkg.name}' in project '#{project.name}'"
          end
        end
        project.task :build => task
      end
      
      pkgs = project.packages.find_all { |pkg| ['ear'].member? pkg.type.to_s }
      pkgs.each do |pkg|
        task = project.task "#{pkg.name}deps" => project.ivy.file_project.task('ivy:resolve') do
          includes = project.ivy.package_include
          excludes = project.ivy.package_exclude
          types = project.ivy.package_type
          confs = project.ivy.package_conf
          if deps = project.ivy.filter(confs, :type => types, :include => includes, :exclude => excludes)
            pkg.add deps, :type => :lib, :path => ''
            info "Adding production libs from conf '#{confs.join(', ')}' to EAR '#{pkg.name}' in project '#{project.name}'"
          end
        end
        project.task :build => task
      end
    end
    
    def add_copy_tasks_for_publish(project)
      ivy_project = project
      until ivy_project.ivy.own_file?
        ivy_project = ivy_project.parent
      end
      project.packages.each do |pkg|
        target_file = project.ivy.publish[pkg] || File.basename(pkg.name).gsub(/-#{project.version}/, '')
        taskname = ivy_project.path_to(ivy_project.ivy.publish_from, target_file)
        if taskname != pkg.name
          project.file taskname => pkg.name do
            verbose "Ivy copying '#{pkg.name}' to '#{taskname}' for publishing"
            FileUtils.mkdir_p File.dirname(taskname) unless File.directory?(File.dirname(taskname))
            FileUtils.cp pkg.name, taskname
          end
        end
        
        ivy_project.task 'ivy:publish' => taskname
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
      
      desc 'Clean the local Ivy result cache to force execution of ivy targets'
      task :clean_result_cache
      
      desc 'Enable the local Ivy result cache by creating the marker file'
      task :enable_result_cache
      
      desc 'Disable the local Ivy result cache by removing the marker file'
      task :disable_result_cache
    end
  end
  
  after_define do |project|
    if project.ivy.enabled?
      IvyExtension.add_ivy_deps_to_java_tasks(project)
      IvyExtension.add_manifest_to_distributeables(project)
      IvyExtension.add_prod_libs_to_distributeables(project)
      IvyExtension.add_copy_tasks_for_publish(project)
      
      namespace 'ivy' do
        task :configure do
          project.ivy.configure
        end
        
        task :clean => :configure do
          # TODO This is redundant, refactor ivy_ant_wrap and this to use a single config object
          rm_rf project.path_to(:reports, 'ivy')
          project.ivy.cleancache
        end
        
        task :clean_result_cache do
          project.send(:info, "Deleting IVY result cache dir '#{project.ivy.result_cache_dir}'")
          rm_rf project.ivy.result_cache_dir
        end
        
        task :enable_result_cache do
          project.send(:info, "Creating IVY caching marker file '#{project.ivy.caching_marker}'")
          touch project.ivy.caching_marker
        end
        
        task :disable_result_cache do
          project.send(:info, "Deleting IVY caching marker file '#{project.ivy.caching_marker}'")
          rm_f project.ivy.caching_marker
        end
        
        task :resolve => "#{project.name}:ivy:configure" do
          project.ivy.__resolve__
        end
        
        task :report => "#{project.name}:ivy:resolve" do
          project.ivy.report
        end
        
        task :publish => "#{project.name}:ivy:resolve" do
          project.ivy.__publish__
        end
      end
    end
  end
end

# Global targets that are not bound to a project
namespace 'ivy' do
  task :clean do
    Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
      project.task('ivy:clean').invoke
    end
  end
  
  task :clean_result_cache do
    Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
      project.task('ivy:clean_result_cache').invoke
    end
  end
  
  task :enable_result_cache do
    Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
      project.task('ivy:enable_result_cache').invoke
    end
  end
  
  task :disable_result_cache do
    Buildr.projects.find_all{ |p| p.ivy.own_file? }.each do |project|
      project.task('ivy:disable_result_cache').invoke
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
