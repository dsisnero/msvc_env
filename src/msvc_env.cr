# TODO: Write documentation for `MsvcEnv`
require "./cli.cr"
require "./msvc_env/constants"
require "./msvc_env/controller"
require "log"

# Setup logging with more detailed output
Log.setup_from_env(default_level: :error)



module MsvcEnv
  VERSION = "0.1.0"
  
  # Global constants instance that can be reused
  class_property constants : Constants? = nil

  # Initialize the constants
  def self.init
    Log.info { "Initializing MsvcEnv" }
    begin
      # Check if we're running on Windows
      {% unless flag?(:windows) %}
        raise "This tool is designed to run on Windows only"
      {% end %}
      
      # Display system information for debugging
      Log.debug { "System information:" }
      Log.debug { "  OS: #{ENV["OS"]? || "Unknown"}" }
      Log.debug { "  PROCESSOR_ARCHITECTURE: #{ENV["PROCESSOR_ARCHITECTURE"]? || "Unknown"}" }
      Log.debug { "  ProgramFiles: #{ENV["ProgramFiles"]? || "Unknown"}" }
      Log.debug { "  ProgramFiles(x86): #{ENV["ProgramFiles(x86)"]? || "Unknown"}" }
      
      # Initialize constants
      @@constants = Constants.new
      @@constants.update_env_path
      Log.info { "Successfully initialized MsvcEnv" }
    rescue ex : Exception
      STDERR.puts "Error initializing Constants: #{ex.message}"
      if ENV["DEBUG"]? == "1"
        STDERR.puts "Stack trace:"
        STDERR.puts ex.backtrace.join("\n")
      else
        STDERR.puts "Run with DEBUG=1 for more detailed error information"
      end
      exit(1)
    end
  end
  
  # Run the initialization when the module is loaded
  init
end
