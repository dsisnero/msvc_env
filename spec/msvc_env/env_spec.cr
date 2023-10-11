require "spec"
require "../../src/msvc_env/env"

it "allows you to yield an msvc env" do
  Process.find_executable("nmake").should be_nil
  MsvcEnv.with_env do
    Process.find_executable("nmake").should be_a(String)
  end
  Process.find_executable("nmake").should be_nil
end
