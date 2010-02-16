$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'rubygems'
require 'test/unit'
require 'ivy4r'
require 'antwrap'
require 'fileutils'

module Ivy
  class Ivy4rTest < Test::Unit::TestCase

    def setup
      @ivy4r = Ivy4r.new
      @ivy_test_xml = File.join(File.dirname(__FILE__), 'ivy', 'ivytest.xml')
    end

    def test_ant_returns_default_wrapper
      assert_not_nil @ivy4r.ant
      assert_kind_of ::Antwrap::AntProject, @ivy4r.ant
      assert_equal Dir.pwd, @ivy4r.ant.basedir
      assert_equal true, @ivy4r.ant.declarative
    end

    def test_ant_returns_always_same_instance
      first = @ivy4r.ant
      second = @ivy4r.ant
      assert_same first, second
    end

    def test_ant_returns_set_instance_if_provided
      provided = "bla"
      @ivy4r.ant = provided
      @ivy4r.instance_eval("@init_done = true")
      assert_equal provided, @ivy4r.ant
    end

    def test_cleancache_returns_nil
      result = @ivy4r.cleancache

      assert_nil result
    end

    def test_info_returns_values_for_file
      result = @ivy4r.info :file => @ivy_test_xml

      assert_not_nil result
      assert_equal 'blau', result['ivy.organisation']
    end

    def test_buildnumber_returns_infos
      result = @ivy4r.buildnumber :organisation => 'oro', :module => 'oro'

      assert_not_nil result
      assert_equal '2.0.8', result['ivy.revision']
      assert_equal '2.0.9', result['ivy.new.revision']
      assert_equal '8', result['ivy.build.number']
      assert_equal '9', result['ivy.new.build.number']
    end

    def test_settings_returns_nil
      result = @ivy4r.settings :file => File.join(File.dirname(__FILE__), 'ivy', 'ivysettings.xml')

      assert_nil result
    end

    def test_configure_returns_custom_properties
      result = @ivy4r.configure :file => File.join(File.dirname(__FILE__), 'ivy', 'ivysettings.xml')

      assert_not_nil result
      assert_equal 'myvalue', result['myparam.ivy.instance']
    end
=begin
    def test_property_setting_getting_to_from_ant
      # use a java hashmap for testing!!
      @ivy4r.instance_eval("def ant_properties;@ant_properties||=java.util.HashMap.new;end")
      name, value = 'name', 'value'
      @ivy4r.property[name] = value

      assert_equal value, @ivy4r.property[name]
    end
=end
    def test_resolve_values_for_file
      result = @ivy4r.resolve :file => @ivy_test_xml

      assert_not_nil result
      assert_equal 'blau', result['ivy.organisation']
      assert_equal 4, result['ivy.resolved.configurations'].size, "has: #{result['ivy.resolved.configurations'].join(', ')}"
    end

    def test_cachepath_using_previous_resolve_contains_jar
      @ivy4r.resolve :organisation => "oro", :module => "oro", :revision => "2.0.8", :keep => true, :inline => true
      result = @ivy4r.cachepath :pathid => 'mytestpathid'
      
      assert_not_nil result
      assert result.any? {|a| a =~ /.*oro.*\.jar/ && a =~ /.*2\.0\.8*/ }
    end

    def test_cachepath_with_resolve_contains_jars
      result = @ivy4r.cachepath :organisation => "oro", :module => "oro", :revision => "2.0.8", :inline => true, :pathid => 'mytestpathid'

      assert_not_nil result
      assert result.any? {|a| a =~ /.*oro.*\.jar/ && a =~ /.*2\.0\.8*/ }
    end

    def test_findrevision_found_correct_version
      result = @ivy4r.findrevision :organisation => "oro", :module => "oro", :revision => "2.0.8"

      assert_equal '2.0.8', result
    end

    def test_findrevision_not_found_nil
      result = @ivy4r.findrevision :organisation => "oro", :module => "oro", :revision => "1unknown1"

      assert_nil result
    end

    def test_artifactproperty_deps_contained
      @ivy4r.resolve :file => @ivy_test_xml
      result = @ivy4r.artifactproperty :name => '[organisation]-[module]', :value => '[revision]'

      assert_not_nil result
      assert result.any? {|k,v| k == 'oro-oro' && v == '2.0.8' }
    end

    def test_artifactreport_xml_returned
      target = File.join(Dir.pwd, "temp_test#{Time.new.strftime('%Y%m%d%H%M%S')}")
      FileUtils.mkdir(target)
      @ivy4r.resolve :file => @ivy_test_xml
      result = @ivy4r.artifactreport :tofile => File.join(target, 'test.xml')

      assert_not_nil result
      assert result =~ /.*<module organisation="oro".*/
    ensure
      FileUtils.rm_rf target
    end

    def test_retrieve_created_dir_with_artifacts
      target = File.join(Dir.pwd, "temp_test#{Time.new.strftime('%Y%m%d%H%M%S')}")
      FileUtils.mkdir(target)
      @ivy4r.resolve :file => @ivy_test_xml
      result = @ivy4r.retrieve :pattern => "#{target}/[organisation]/[module].[ext]"

      assert_nil result
      assert Dir.glob(File.join(target, '**/oro.jar')).size > 0, "Contains the artifacts"
    ensure
      FileUtils.rm_rf target
    end

    def test_report_created_reports
      target = File.join(Dir.pwd, "temp_test#{Time.new.strftime('%Y%m%d%H%M%S')}")
      FileUtils.mkdir(target)
      @ivy4r.resolve :file => @ivy_test_xml
      result = @ivy4r.report :todir => target

      assert_nil result
      assert Dir.glob(File.join(target, '**/*')).size > 0, "Contains the reports"
    ensure
      FileUtils.rm_rf target
    end

    def test_buildlist_correct_list
      target = File.join(File.dirname(__FILE__), "buildlist")
      result = @ivy4r.buildlist :reference => 'testpath', :nested => {
        :fileset => [
          {:dir => File.join(target, "sub"), :includes => '**/buildfile'},
          {:dir => File.join(target, "p1"), :includes => 'buildfile'}
        ]
      }
      
      assert_equal 3, result.size
      result.map! { |file| File.expand_path(file) }
      assert_equal File.expand_path(File.join(target, "p1", "buildfile")), result[0]
      assert_equal File.expand_path(File.join(target, "sub", "p2", "buildfile")), result[1]
      assert_equal File.expand_path(File.join(target, "sub", "p3", "buildfile")), result[2]
    end

    def test_makepom_returns_content
      target = File.join(File.dirname(__FILE__), "testpom.xml")
      result = @ivy4r.makepom :ivyfile => @ivy_test_xml, :pomfile => target, :nested => {
        :mapping => {:conf => 'default', :scope => 'runtime' }
      }

      assert_equal IO.read(target), result
    ensure
      FileUtils.rm target
    end

    #def test_listmodules_lists_ivy_stuff
    #  result = @antwrap.listmodules :organisation => '*apache*', :module => '*ivy*', :revision => '2.*',
    #    :matcher => 'glob', :property => 'rums-[organisation][module]', :value => 'found'
    #  assert result.find {|k,v| k =~ /rums-/ && v == 'found'}, "found: #{result.inspect}"
    #end
  end
end
