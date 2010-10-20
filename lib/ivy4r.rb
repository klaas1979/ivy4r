require 'ivy4r_jars'
require 'antwrap'
require 'ivy/targets'

=begin rdoc
Simple wrapper that maps the ant ivy targets one to one to ruby. See the {Apache Ivy}[http://ant.apache.org/ivy/index.html]
for more informations about the parameters for a call. All ivy ant targets have the equivalent
name in this class.

The standard parameters are provided as Hash, i.e.:
  <ivy:configure file="settings.xml" settingsId="my.id" />
is
  ivy4r.configure :file => "settings.xml", :settingsId => 'my.id'

You can use nested options via the nested attribute:
  <ivy:buildlist reference="testpath">
    <fileset dir="target/p1" includes="buildfile" />
  </ivy:buildlist>
is
  @ivy4r.buildlist :reference => 'testpath', :nested => {
    :fileset => {:dir => 'target/p1', :includes => 'buildfile'}
  }

you can nest more than on element of the same type using an array:
  <ivy:buildlist reference="testpath">
    <fileset dir="target/sub" includes="**/buildfile" />
    <fileset dir="target/p1" includes="buildfile" />
  </ivy:buildlist>
is
  @ivy4r.buildlist :reference => 'testpath', :nested => {
    :fileset => [
      {:dir => 'target/sub', :includes => '**/buildfile'},
      {:dir => 'target/p1', :includes => 'buildfile'}
    ]
  }
=end
class Ivy4r

  VERSION = '0.12.5'
  
  # Set the ant home directory to load ant classes from if no custom __antwrap__ is provided
  # and the default provided ant version 1.7.1 should not be used.
  # Must be set before any call to method that uses the ivy is made.
  attr_accessor :ant_home
  
  # Defines the directory to load ivy libs and its dependencies from
  attr_accessor :lib_dir
  
  # Optional ant variable <tt>ivy.project.dir</tt> to add to ant environment before loading ivy
  # defaults to the __lib_dir__
  attr_accessor :project_dir
  
  # The ant property name to use for references to environment properties in ant and ivy,
  # defaults to 'env'
  attr_accessor :environment_property
  
  # To provide a custom __antwrap__ to use instead of default one
  attr_accessor :ant
  
  # Access to ivy settings set via configure or settings method.
  attr_accessor :settings_file
  
  # Donates the base directory for the cached files, if nil no caching is enabled
  attr_accessor :cache_dir
  
  # Initalizes ivy4r with optional ant wrapper object. Sets ant home dir and ivy lib dir
  # to default values from __Ivy4rJars__ gem.
  def initialize(ant_instance = nil, &block)
    @ant_home = ::Ivy4rJars.ant_home_dir
    @lib_dir = ::Ivy4rJars.lib_dir
    @project_dir = @lib_dir
    @environment_property = 'env'
    @ant = ant_instance
    
    if block
      if block.arity > 1
        raise ArgumentError, "To many arguments expected=1 given=#{block.arity}"
      elsif block.arity == 1
        yield self
      else
        instance_eval(&block)
      end
    end
  end
  
  # Calls the __cleancache__ ivy target with given parameters.
  def cleancache(*params)
    Ivy::Cleancache.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __settings__ ivy target with given parameters.
  def settings(*params)
    settings_task = Ivy::Settings.new(ant, nil) # do not cache settings
    result = settings_task.execute(*params)
    @settings_file = settings_task.params[:file]
    result
  end
  
  # Calls the __configure__ ivy target with given parameters.
  def configure(*params)
    configure_task = Ivy::Configure.new(ant, nil) # do not cache configure
    result = configure_task.execute(*params)
    @settings_file = configure_task.params[:file]
    result
  end
  
  # Calls the __info__ ivy target with given parameters and returns info as hash.
  def info(*params)
    Ivy::Info.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __buildnumber__ ivy target with given parameters and returns info as hash.
  def buildnumber(*params)
    Ivy::Buildnumber.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __listmodules__ ivy target with given parameters and returns info as hash.
  def listmodules(*params) #:nodoc:
    Ivy::Listmodules.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __makepom__ ivy target with given parameters and returns pom content.
  def makepom(*params)
    Ivy::Makepom.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __resolve__ ivy target with given parameters and returns info as hash.
  def resolve(*params)
    Ivy::Resolve.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __retrieve__ ivy target with given parameters.
  def retrieve(*params)
    Ivy::Retrieve.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __publish__ ivy target with given parameters.
  def publish(*params)
    Ivy::Publish.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __cachepath__ ivy target with given parameters and returns
  # array containing absolute file paths to all artifacts contained in result
  def cachepath(*params)
    Ivy::Cachepath.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __findrevision__ ivy target with given parameters and returns
  # array containing absolute file paths to all artifacts contained in result
  def findrevision(*params)
    Ivy::Findrevision.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __artifactproperty__ ivy target with given parameters and returns
  # map with all defined properties
  def artifactproperty(*params)
    Ivy::Artifactproperty.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __buildlist__ ivy target with given parameters and returns
  # the resulting buildlist
  def buildlist(*params)
    Ivy::Buildlist.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __artifactreport__ ivy target with given parameters and returns
  # the created xml.
  def artifactreport(*params)
    Ivy::Artifactreport.new(ant, cache_dir).execute(*params)
  end
  
  # Calls the __report__ ivy target with given parameters
  def report(*params)
    Ivy::Report.new(ant, cache_dir).execute(*params)
  end
  
  # Used to get or set ant properties.
  # [set] <tt>property['name'] = value</tt> sets the ant property with name to given value no overwrite
  # [get] <tt>property[matcher]</tt> gets property that is equal via case equality operator (<tt>===</tt>)
  def property
    AntPropertyHelper.new(ant, ant_properties)
  end
  
  # Returns the __antwrap__ instance to use for all internal calls creates a default
  # instance if no instance has been set before.
  def ant
    @ant ||= ::Antwrap::AntProject.new(:ant_home => ant_home,
      :name => "ivy-ant", :basedir => Dir.pwd, :declarative => true)
    init(@ant) if should_init?
    @ant
  end
  
  private
  def should_init?
    @init_done.nil? || @init_done == false
  end
  
  def init(ant)
    @init_done = true
    ant.property :environment => environment_property
    ant.property :name => 'ivy.project.dir', :value => project_dir
    ant.path :id => 'ivy.lib.path' do
      ant.fileset :dir => lib_dir, :includes => '*.jar'
    end
    
    ant.typedef :name => "ivy_settings", :classname => "org.apache.ivy.ant.IvyAntSettings", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader', :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_configure", :classname => "org.apache.ivy.ant.IvyConfigure", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_resolve", :classname => "org.apache.ivy.ant.IvyResolve", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_retrieve", :classname => "org.apache.ivy.ant.IvyRetrieve", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_deliver", :classname => "org.apache.ivy.ant.IvyDeliver", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_publish", :classname => "org.apache.ivy.ant.IvyPublish", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_extract", :classname => "org.apache.ivy.ant.IvyExtractFromSources", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_cachepath", :classname => "org.apache.ivy.ant.IvyCachePath", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_cachefileset", :classname => "org.apache.ivy.ant.IvyCacheFileset", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_report", :classname => "org.apache.ivy.ant.IvyReport", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_repreport", :classname => "org.apache.ivy.ant.IvyRepositoryReport", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_var", :classname => "org.apache.ivy.ant.IvyVar", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_check", :classname => "org.apache.ivy.ant.IvyCheck", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_artifactproperty", :classname => "org.apache.ivy.ant.IvyArtifactProperty", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_buildlist", :classname => "org.apache.ivy.ant.IvyBuildList", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_install", :classname => "org.apache.ivy.ant.IvyInstall", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_convertpom", :classname => "org.apache.ivy.ant.IvyConvertPom", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_makepom", :classname => "org.apache.ivy.ant.IvyMakePom", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_artifactreport", :classname => "org.apache.ivy.ant.IvyArtifactReport", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_info", :classname => "org.apache.ivy.ant.IvyInfo", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_addpath", :classname => "org.apache.ivy.ant.AddPathTask", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_listmodules", :classname => "org.apache.ivy.ant.IvyListModules", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_findrevision", :classname => "org.apache.ivy.ant.IvyFindRevision", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_buildnumber", :classname => "org.apache.ivy.ant.IvyBuildNumber", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
    ant.taskdef :name => "ivy_cleancache", :classname => "org.apache.ivy.ant.IvyCleanCache", :classpathref => "ivy.lib.path", :loaderRef => 'ivy.lib.path.loader'
  end
  
  # Returns the ant properties, note that this are java objects.
  def ant_properties
    ant.project.properties
  end
end

AntPropertyHelper = Struct.new(:ant, :ant_properties) do #:nodoc:
  def []=(name, value) #:nodoc:
    ant.property :name => name, :value => value
  end
  
  def [](matcher) #:nodoc:
    property = ant_properties.find {|p| matcher === p[0] }
    property ? property[1] : nil
  end
end
