# TODO: Write documentation for `MsvcEnv`
require "./cli.cr"
require "./msvc_env/constants"
require "./msvc_env/controller"
require "./debug_helper"

module MsvcEnv
  VERSION = "0.1.0"

  # Global constants instance that can be reused
  @@constants : Constants? = nil
  @@initialized = false

  # Initialize the constants
  def self.init
    return if @@initialized

    puts "Initializing MsvcEnv..."
    begin
      # Check if we're running on Windows
      {% unless flag?(:windows) %}
        puts "Warning: This tool is designed for Windows only"
        @@initialized = true
        return
      {% end %}

      # Display system information for debugging
      puts "System information:"
      puts "  OS: #{ENV["OS"]? || "Unknown"}"
      puts "  PROCESSOR_ARCHITECTURE: #{ENV["PROCESSOR_ARCHITECTURE"]? || "Unknown"}"
      puts "  ProgramFiles: #{ENV["ProgramFiles"]? || "Unknown"}"
      puts "  ProgramFiles(x86): #{ENV["ProgramFiles(x86)"]? || "Unknown"}"

      # Initialize constants with explicit error handling
      begin
        constants = Constants.new
        constants.update_env_path
        @@constants = constants
        puts "Successfully initialized MsvcEnv"
      rescue ex : IndexError
        STDERR.puts "ERROR: Index out of bounds in Constants initialization"
        STDERR.puts "This usually happens when trying to access an array element that doesn't exist"
        STDERR.puts "Exception details: #{ex.message}"
        STDERR.puts ex.backtrace.join("\n") if ENV["DEBUG"]? == "1"
        # Don't exit, just continue with nil constants
      rescue ex : Exception
        STDERR.puts "Error initializing Constants: #{ex.message}"
        STDERR.puts "Stack trace:" if ENV["DEBUG"]? == "1"
        STDERR.puts ex.backtrace.join("\n") if ENV["DEBUG"]? == "1"
        # Don't exit, just continue with nil constants
      end
    rescue ex : Exception
      STDERR.puts "Error in MsvcEnv initialization: #{ex.message}"
      STDERR.puts ex.backtrace.join("\n") if ENV["DEBUG"]? == "1"
    ensure
      @@initialized = true
    end
  end

  # Get the constants instance
  def self.constants
    init unless @@initialized
    @@constants
  end

  # Run diagnostics if in debug mode
  if ENV["DEBUG"]? == "1"
    puts "Running in DEBUG mode"
    DebugHelper.run_diagnostics
  end
end

# Run the initialization when the module is loaded, but don't exit on failure
begin
  MsvcEnv.init
rescue ex
  STDERR.puts "Warning: MsvcEnv initialization failed: #{ex.message}"
end
