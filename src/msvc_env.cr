# TODO: Write documentation for `MsvcEnv`
require "./cli.cr"
require "./msvc_env/constants"
require "log"

Log.setup_from_env

module MsvcEnv
  Log = Log.for(self)
  VERSION = "0.1.0"

  # Initialize the constants
  def self.init
    Log.info { "running init" }
    begin
      # Set debug level for more verbose output
      Log.setup(:debug)
      
      constants = Constants.new
      puts "Successfully initialized MsvcEnv"
    rescue ex : Exception
      STDERR.puts "Error initializing Constants: #{ex.message}"
      STDERR.puts ex.backtrace.join("\n") if ENV["DEBUG"]? == "1"
      exit(1)
    end
  end
  
  # Run the initialization when the module is loaded
  init
end
