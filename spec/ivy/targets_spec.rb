describe "Ivy::Targets" do

  before(:each) do
    ivy4r = Ivy4r.new
    @ivy_test_xml = File.join(File.dirname(__FILE__), '..', '..', 'spec_files', 'ivy.xml')
    @info = Ivy::Info.new(ivy4r.ant)
  end

  it "#execute with empty parameters missing mandatory error" do
    lambda{ @info.execute({}) }.should raise_error(ArgumentError)
  end

  it "#execute validate with unknown parameters error" do
    lambda{ @info.execute(:unknown_parameter => 'unknown') }.should raise_error(ArgumentError)
  end

  it "#execute simple file correct return values" do
    result = @info.execute(:file => @ivy_test_xml)

    result.should_not be nil
    %w[ivy.organisation ivy.revision ivy.module].each do |var|
      result.keys.should include(var)
    end
    result['ivy.organisation'].should eq('blau')
  end

end
