require "./options"
require "./constants"
require "../with_env"

module MsvcEnv
  class Controller
    include WithEnv
    YEARS               = ["2022", "2019", "2017", "2015"]
    PATH_LIKE_VARIABLES = ["PATH", "INCLUDE", "LIB", "LIBPATH"]

    # Define a helper method to split environment variable strings into a dictionary.
    def parse_environment_vars(env_string : String) : Hash(String, String)
      h = Hash(String, String).new
      env_string.each_line do |line|
        next unless line.includes? "="
        ar = line.split("=")
        h[ar[0].strip] = ar[1].strip unless ar.empty?
      end
      h
    end

    # Define a method to set up the MSVC Developer Command Prompt.
    def setup_msvcdev_cmd(opt : Options?)
      # Constants related to the MSVC setup.
      constants = Constants.new

      if opt
        # Map architecture aliases.
        arch_aliases = {
          "win32"  => "x86",
          "win64"  => "x64",
          "x86_64" => "x64",
          "x86-64" => "x64",
        }
        # Convert architecture to lowercase and map to actual value.
        arch = arch_aliases.fetch(opt.arch.downcase, opt.arch.downcase) if opt.arch

        # Prepare the command to execute VC++ configuration batch file.
        vcvars_args = arch ? [arch] : [] of String
        vcvars_args << "uwp" if opt.uwp
        vcvars_args << opt.sdk.not_nil! if opt.sdk
        vcvars_args << "-vcvars_ver=#{opt.toolset}" if opt.toolset
        vcvars_args << "-vcvars_spectre_libs=spectre" if opt.spectre
        vsbatch = constants.find_vcvarsall(opt.version)

        %Q{"#{constants.find_vcvarsall(opt.version)}" #{vcvars_args.join(" ")}}
      else
        %Q("#{constants.find_vcvarsall}" x64 )
      end
    end

    def msvc_env(&)
      vcsvars_cmd = setup_msvcdev_cmd(nil)
      _, new_env = run_vc_batch_file(vcsvars_cmd)
      with_env(new_env) do
        yield
      end
    end

    def run(opt : Options)
      program = opt.program
      args = opt.args
      raise "opt.program needed" unless program
      vcvars_cmd = setup_msvcdev_cmd(opt)
      old_env, new_env = run_vc_batch_file(vcvars_cmd)
      update_env(old_env, new_env)
      args = Process.parse_arguments(args.not_nil!) if args
      puts "Running #{program} with #{args}"
      Process.run(command: program, args: args, output: STDOUT)
    rescue ex : Exception
      puts ex.message
      puts ex.backtrace
      raise ex
    end

    def run_vc_batch_file(cmd)
      # Run the VC++ configuration batch file and capture the environment output.
      io_output = IO::Memory.new
      io_error = IO::Memory.new
      vsvars_cmd = "cmd /C set && cls && #{cmd} && cls && set"

      temporary_batch_file = File.tempfile(suffix: ".bat") do |f|
        f.puts vsvars_cmd
      end

      puts "running cmd\n#{vsvars_cmd}"
      status = Process.run(command: "cmd", args: ["/C", temporary_batch_file.path], output: io_output, error: io_error)
      cmd_output = io_output.to_s
      error_output = io_error.to_s

      unless status.success?
        puts "Error #################\n\n"
        puts error_output
      end

      # Split the output into parts.
      cmd_output_parts = cmd_output.split("\f").to_a

      # Ensure there are three parts.
      if cmd_output_parts.size != 3
        raise "Couldn't split the output into pages: #{cmd_output_parts[2]}"
      end

      # Convert the parts to UTF-8 strings.
      old_environment = parse_environment_vars(cmd_output_parts[0])
      vcvars_output = cmd_output_parts[1]
      new_environment = parse_environment_vars(cmd_output_parts[2])

      # Check for error messages in vcvars_output.
      error_messages = vcvars_output.lines.select { |line| line.includes?("[ERROR") && !line.includes?("Error in script usage. the correct usage is:") }
      unless error_messages.empty?
        raise "Invalid parameters\n#{error_messages.join("\n")}"
      end

      {old_environment, new_environment}
    end

    def filter_path_value(path : String) : String
      h = Hash(String, String).new
      path.split(";").each_with_object(h) do |p|
        next if h.has_key? p
        h[p] = p
      end
      h.keys.join(";")
    end

    def update_env(old_env, new_env)
      # Update environment variables with new values.
      new_env.each do |name, new_value|
        old_value = old_env[name]?
        # Only update if it's a new variable or the value has changed.
        if old_value.nil? || !(old_value.downcase == new_value.downcase)
          if name.in?(PATH_LIKE_VARIABLES)
            effective_value = filter_path_value(new_value)
            ENV[name] = effective_value
          else
            ENV[name] = new_value
          end
        end
      end

      puts "Configured Developer Command Prompt"

      nil
    end
  end
end
