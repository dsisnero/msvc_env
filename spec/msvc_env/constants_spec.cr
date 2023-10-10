require "../spec_helper"

describe MsvcEnv::Constants do
  # TODO: Write tests

  it "can find vswereall" do
    constants = MsvcEnv::Constants.new
    (File.exists? constants.vswhere_path).should be_true
  end

  it "finds_with_vswhereall" do
    constants = MsvcEnv::Constants.new
    path = constants.find_vcvarsall
    path.should be_a Path
    path.to_s.should contain("vcvarsall.bat")
  end

  # it "finds other versins" do
  #   constants = MsvcEnv::Constants.new
  #   path = constants.find_vcvarsall("2022")
  #   path.should be_a Path
  #   path.to_s.should contain("vcvarsall.bat")
  # end

  it "works" do
    true.should eq(true)
  end
end
