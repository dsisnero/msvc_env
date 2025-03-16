# TODO: Write documentation for `MsvcEnv`
require "./cli.cr"
require "./msvc_env/constants"
require "./msvc_env/controller"
require "./debug_helper"
require "log"

# Setup logging with more detailed output
Log.setup(:debug) if ENV["DEBUG"]? == "1" || ENV["LOG_LEVEL"]? == "DEBUG"
Log.setup(:info) if ENV["LOG_LEVEL"]? == "INFO"
Log.setup(:error) if !ENV["DEBUG"]? && ENV["LOG_LEVEL"]?.nil?



module MsvcEnv
  VERSION = "0.1.0"
  
  # Global constants instance that can be reused
  class_property constants : Constants? = nil

  # Initialize the constants
  def self.init
    puts "Initializing MsvcEnv..."
    begin
      # Check if we're running on Windows
      {% unless flag?(:windows) %}
        raise "This tool is designed to run on Windows only"
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
        STDERR.puts ex.backtrace.join("\n")
        exit(1)
      end
    rescue ex : Exception
      STDERR.puts "Error initializing Constants: #{ex.message}"
      STDERR.puts "Stack trace:"
      STDERR.puts ex.backtrace.join("\n")
      exit(1)
    end
  end
  
  # Run diagnostics if in debug mode
  if ENV["DEBUG"]? == "1"
    puts "Running in DEBUG mode"
    DebugHelper.run_diagnostics
  end
  
  # Run the initialization when the module is loaded
  init
end
