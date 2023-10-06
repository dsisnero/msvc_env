require "./spec_helper"
describe Controller do
  it "gets environment hashes" do
    opts = Options.new
    opts.program = "nmake"
    controller = Controller.new
    controller.run(opts)
  end
end
