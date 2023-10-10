require "../spec_helper"
describe MsvcEnv::Controller do
  it "gets environment hashes" do
    opts = MsvcEnv::Options.new
    opts.program = "nmake"
    controller = MsvcEnv::Controller.new
    controller.run(opts)
  end
end
