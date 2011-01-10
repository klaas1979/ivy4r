describe "Test Functional ::Ivy4r" do

  before(:each) do
    @ivy4r = Ivy4r.new
    spec_files = File.join(File.dirname(__FILE__), '..', 'spec_files')
    @ivy_xml = File.join(spec_files, 'ivy.xml')
    @ivy_settings_xml = File.join(spec_files, 'ivysettings.xml')
    @buildlist_dir = File.join(spec_files, 'buildlist')
  end

  it "#buildnumber returns next version" do
    result = @ivy4r.buildnumber :organisation => 'oro', :module => 'oro'

    result.should_not be nil
    result['ivy.revision'].should eq('2.0.8')
    result['ivy.new.revision'].should eq('2.0.9')
    result['ivy.build.number'].should eq('8')
    result['ivy.new.build.number'].should eq('9')
  end

  it "#resolve returns resolve values as map" do
    result = @ivy4r.resolve :file => @ivy_xml

    result.should_not be nil
    result['ivy.organisation'].should eq('blau')
    result['ivy.resolved.configurations'].size.should eq(4)
  end

  it "#cachpath contains correct jars from previous resolve" do
    @ivy4r.resolve :organisation => "oro", :module => "oro", :revision => "2.0.8", :keep => true, :inline => true
    result = @ivy4r.cachepath :pathid => 'mytestpathid'

    result.any? {|a| a =~ /.*oro.*\.jar/ && a =~ /.*2\.0\.8*/ }.should be true
  end

  it "#cachpath with inline resolve contains correct jars" do
    result = @ivy4r.cachepath :organisation => "oro", :module => "oro", :revision => "2.0.8", :inline => true, :pathid => 'mytestpathid'

    result.any? {|a| a =~ /.*oro.*\.jar/ && a =~ /.*2\.0\.8*/ }.should be true
  end

  it "#findrevision finds correct version" do
    result = @ivy4r.findrevision :organisation => "oro", :module => "oro", :revision => "2.0.8"

    result.should eq('2.0.8')
  end

  it "#findrevision returns nil for unknown revision on existing module" do
    result = @ivy4r.findrevision :organisation => "oro", :module => "oro", :revision => "1unknown1"

    result.should be nil
  end

  it "#artifactproperty dependencies are contained in result" do
    @ivy4r.resolve :file => @ivy_xml
    result = @ivy4r.artifactproperty :name => '[organisation]-[module]', :value => '[revision]'

    result.any? {|k,v| k == 'oro-oro' && v == '2.0.8' }.should be true
  end

  it "#artifactreport creates xml report file" do
    begin
      target = File.join(Dir.pwd, "temp_test#{Time.new.strftime('%Y%m%d%H%M%S')}")
      FileUtils.mkdir(target)
      @ivy4r.resolve :file => @ivy_xml
      result = @ivy4r.artifactreport :tofile => File.join(target, 'test.xml')

      result.should_not be nil
      result.should match(/.*<module organisation="oro".*/)
    ensure
      FileUtils.rm_rf target
    end
  end

  it "#retrieve creates directory with artifacts" do
    begin
      target = File.join(Dir.pwd, "temp_test#{Time.new.strftime('%Y%m%d%H%M%S')}")
      FileUtils.mkdir(target)
      @ivy4r.resolve :file => @ivy_xml
      @ivy4r.retrieve :pattern => "#{target}/[organisation]/[module].[ext]"

      Dir.glob(File.join(target, '**/oro.jar')).size.should be > 0
    ensure
      FileUtils.rm_rf target
    end
  end

  it "#report creates reports" do
    begin
      target = File.join(Dir.pwd, "temp_test#{Time.new.strftime('%Y%m%d%H%M%S')}")
      FileUtils.mkdir(target)
      @ivy4r.resolve :file => @ivy_xml
      @ivy4r.report :todir => target

      Dir.glob(File.join(target, '**/*')).size.should be > 0
    ensure
      FileUtils.rm_rf target
    end
  end

  it "#buildlist returns list in correct order for linear build" do
    target = @buildlist_dir
    result = @ivy4r.buildlist :reference => 'testpath', :nested => {
      :fileset => [
        {:dir => File.join(target, "sub"), :includes => '**/buildfile'},
        {:dir => File.join(target, "p1"), :includes => 'buildfile'}
      ]
    }

    result.size.should be 3
    result.map! { |file| File.expand_path(file) }
    File.expand_path(File.join(target, "p1", "buildfile")).should eq(result[0])
    File.expand_path(File.join(target, "sub", "p2", "buildfile")).should eq(result[1])
    File.expand_path(File.join(target, "sub", "p3", "buildfile")).should eq(result[2])
  end

  it "#makepom creates a pom for ivy.xml" do
    begin
      target = File.join(File.dirname(__FILE__), "testpom.xml")
      result = @ivy4r.makepom :ivyfile => @ivy_xml, :pomfile => target, :nested => {
        :mapping => {:conf => 'default', :scope => 'runtime' }
      }

      IO.read(target).should eq(result)
    ensure
      FileUtils.rm target
    end

  end
end

