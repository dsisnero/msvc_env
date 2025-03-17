require "option_parser"
require "./msvc_env/controller"

module MsvcEnv
  opt = Options.new

  parser = ::OptionParser.new do |parser|
    parser.banner = "Usage: msvc_env [opts] PROGRAM PROGRAM_OPTIONS"

    parser.on("-a ARCH", "--arch ARCH", "Target architecture (default: x64)") do |arch|
      opt.arch = arch
    end

    parser.on("--sdk SDK", "Windows SDK number to build for") do |sdk|
      opt.sdk = sdk
    end

    # parser.on("--[no-]spectre", "Enable Spectre mitigations (default: false)") do |spectre|
    #   opt.spectre = spectre
    # end

    parser.on("--toolset TOOLSET", "VC++ compiler toolset version") do |toolset|
      opt.toolset = toolset
    end

    # parser.on("--[no-]uwp", "Build for Universal Windows Platform (default: false)") do |uwp|
    #   opt.uwp = uwp
    # end

    parser.on("--version VERSION", "The Visual Studio version to use (e.g., '16.0' for 2019)") do |version|
      opt.version = version
    end

    parser.on("-h", "--help", "Show this help message") do
      puts parser
      exit
    end

    parser.unknown_args do |args|
        opt.program = args.shift
        
    end

    parser.invalid_option do |option|
      opt.args = option
    end
  end

  begin
    parser.parse(ARGV)
    controller = Controller.new
    
    # If no program is specified, launch an interactive shell with the VS environment
    if opt.program.nil?
      puts "Setting up Visual Studio Developer Command Prompt environment..."
      
      # Determine the shell to use (cmd.exe by default)
      shell = ENV["COMSPEC"]? || "cmd.exe"
      
      # Set up options for the shell
      opt.program = shell
      
      # For cmd.exe, we want to show a custom prompt
      if shell.downcase.includes?("cmd")
        opt.args = "/k title Visual Studio Developer Command Prompt && prompt $P$_VS$G "
      end
    end
    
    # Run the program (or shell) with the VS environment
    controller.run(opt)
  rescue ex : Exception
    STDERR.puts "Error initializing Constants: #{ex}"
    exit(1)

    {% unless flag?(:windows) %}
      STDERR.puts "This is not a Windows virtual environment!"
      exit(1)
    {% end %}
  end
end
