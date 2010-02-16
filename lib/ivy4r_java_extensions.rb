# basic stuff
require 'ivy4r'

# java extensions
Dir[Ivy4rJars.lib_dir + "/*.jar"].each {|jar| require jar}
require 'ivy/java/all_version_matcher'

class Ivy4r
  # Returns the ivy instance for underlying ant project with the current ivy settings.
  def ivy_instance
    unless @ivy_instance
      variable_container = Java::OrgApacheIvyAnt::IvyAntVariableContainer.new(ant.project)
      settings_file = find_settings_file(variable_container) unless settings_file
      raise "no settings file set and no default settings found, cannot create ivy instance" unless settings_file
      raise "settings file does not exist: #{settings_file}" unless File.exists? settings_file

      settings = Java::OrgApacheIvyCoreSettings::IvySettings.new(variable_container)
      settings.base_dir = ant.project.base_dir
      @ivy_instance = Java::OrgApacheIvy::Ivy.new_instance(settings)
      @ivy_instance.configure(Java::JavaIo::File.new(settings_file))
    end

    @ivy_instance
  end

  # Returns the ant references, note that this are java objects.
  def ant_references
    ant.project.references
  end

  private
  def find_settings_file(variable_container)
    settings_file_name = variable_container.get_variable("ivy.conf.file") || variable_container.get_variable("ivy.settings.file")
    setting_locations = [
      File.join(ant.project.base_dir.absolute_path, settings_file_name),
      File.join(ant.project.base_dir.absolute_path, 'ivyconf.xml'),
      settings_file_name,
      'ivyconf.xml'
    ]
    setting_locations.find {|path| File.exists? path }
  end
end
