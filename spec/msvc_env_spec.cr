require "./spec_helper"

describe Constants do
  # TODO: Write tests

  it "can find vswereall" do
    constants = Constants.new
    (File.exists? constants.vswhere_path).should be_true
    pp constants
  end

  it "finds_with_vswhereall" do
    constants = Constants.new
    path = constants.find_vcvarsall
    path.should be_a Path
    path.to_s.should contain("vcvarsall.bat")
  end

  # it "finds other versins" do
  #   constants = Constants.new
  #   path = constants.find_vcvarsall("2022")
  #   path.should be_a Path
  #   path.to_s.should contain("vcvarsall.bat")
  # end

  it "works" do
    true.should eq(true)
  end
end
