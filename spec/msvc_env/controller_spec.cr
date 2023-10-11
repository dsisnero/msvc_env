require "../spec_helper"

describe "#with_env" do
  it "allows you to yield an msvc env" do
    controller = MsvcEnv::Controller.new
    Process.find_executable("nmake").should be_nil
    controller.msvc_env do
      Process.find_executable("nmake").should be_a(String)
    end
    Process.find_executable("nmake").should be_nil
  end
end

describe MsvcEnv::Controller do
  it "gets environment hashes" do
    Process.find_executable("nmake").should be_nil
    old_env = ENV.to_h { |k, v| {k, v} }
    opts = MsvcEnv::Options.new
    opts.program = "nmake"
    controller = MsvcEnv::Controller.new
    controller.run(opts)
    Process.find_executable("nmake").should be_a(String)
    ENV.clear
    old_env.each do |k, v|
      ENV[k] = v
    end
  end
end
