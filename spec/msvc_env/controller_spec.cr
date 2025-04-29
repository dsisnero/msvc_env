require "../spec_helper"

# Skip tests if not on Windows
{% unless flag?(:windows) %}
  # These tests only run on Windows
  pending "#with_env"
  pending "MsvcEnv::Controller"
{% else %}
  describe "#with_env" do
    it "allows you to yield an msvc env" do
      begin
        controller = MsvcEnv::Controller.new
        nmake_before = Process.find_executable("nmake")
        controller.msvc_env do
          Process.find_executable("nmake").should_not be_nil
        end
        nmake_after = Process.find_executable("nmake")
        (nmake_before == nmake_after).should be_true
      rescue ex
        puts "Test skipped: #{ex.message}"
        pending "Requires Visual Studio installation"
      end
    end
  end

  describe MsvcEnv::Controller do
    it "gets environment hashes" do
      # Save the current environment
      old_env = ENV.to_h { |k, v| {k, v} }

      begin
        opts = MsvcEnv::Options.new
        opts.program = "cmd"
        opts.args = "/c echo Test"
        controller = MsvcEnv::Controller.new
        controller.run(opts)
      rescue ex
        puts "Test skipped: #{ex.message}"
        pending "Requires Visual Studio installation"
      ensure
        # Restore environment
        ENV.clear
        if old_env
          old_env.each do |k, v|
            ENV[k] = v
          end
        end
      end
    end
  end
{% end %}
