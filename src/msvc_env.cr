# TODO: Write documentation for `MsvcEnv`
require "./cli.cr"
require "./msvc_env/constants"

module MsvcEnv
  VERSION = "0.1.0"

  # Initialize the constants
  def self.init
    begin
      constants = Constants.new
      puts "Successfully initialized MsvcEnv"
    rescue ex
      STDERR.puts "Error initializing Constants: #{ex.message}"
      exit(1)
    end
  end
  
  # Run the initialization when the module is loaded
  init
end
