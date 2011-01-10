describe "::Ivy4r" do

  before(:each) do
    @ivy4r = Ivy4r.new
    @ivy_xml = File.join(File.dirname(__FILE__), '..', 'spec_files', 'ivy.xml')
    @ivy_settings_xml = File.join(File.dirname(__FILE__), '..', 'spec_files', 'ivysettings.xml')
  end

  it "#ant returns default AntWrapper" do
    @ivy4r.ant.should_not be nil
    @ivy4r.ant.should be_kind_of(::Antwrap::AntProject)
    @ivy4r.ant.basedir.should eq(Dir.pwd)
    @ivy4r.ant.declarative.should be true
  end

  it "#ant returns always same instance" do
    @ivy4r.ant.should be @ivy4r.ant
  end

  it "#ant returns provided instance if set previously" do
    provided = "bla"
    @ivy4r.ant = provided
    @ivy4r.instance_eval("@init_done = true")
    @ivy4r.ant.should be provided
  end

  it "#cleancache returns nil" do
    @ivy4r.cleancache.should be nil
  end

  it "#info returns data from used ivy.xml" do
    result = @ivy4r.info :file => @ivy_xml

    result.should_not be nil
    result['ivy.organisation'].should eq('blau')
    result['ivy.module'].should eq('testmodule')
    result['ivy.revision'].should eq('2.20.0')
  end

  it "#settings returns nil" do
    @ivy4r.settings(:file => @ivy_settings_xml).should be nil
  end

  it "#configure returns custom properties" do
    result = @ivy4r.configure(:file => @ivy_settings_xml)

    result.should_not be nil
    result['myparam.ivy.instance'].should eq('myvalue')
  end
end
