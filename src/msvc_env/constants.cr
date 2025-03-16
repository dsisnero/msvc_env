require "set"
require "hash"
require "log"
module MsvcEnv
  struct Constants

    Log = ::Log.for(self)
    EDITIONS = ["Enterprise", "Professional", "Community", "Preview", "BuildTools"]

    property program_files_x86 : Path
    property program_files : Path
    getter vs_year_version : Hash(String, String)
    property vswhere_path : Path
    getter vswhere_exe : Path?

    def initialize
      Log.info { "initializing constants"}
      @vs_year_version = Hash{
        "2022" => "17.0",
        "2019" => "16.0",
        "2017" => "15.0",
        "2015" => "14.0",
        "2013" => "12.0",
      }
      
      # Get program files paths
      @program_files_x86 = pathbuf_from_key("ProgramFiles(x86)")
      @program_files = pathbuf_from_key("ProgramFiles")
      
      # Find vswhere.exe
      @vswhere_path = @program_files_x86.join("Microsoft Visual Studio/Installer").normalize
      Log.debug { "Looking for vswhere.exe at: #{@vswhere_path}" }
      
      if exe = find_vswhere_exe
        Log.info { "vswhere found at: #{exe}" }
        @vswhere_exe = exe
      else
        Log.error { "vswhere.exe not found - Visual Studio detection may fail" }
        # We'll continue and try to find Visual Studio without vswhere
      end
    
    end

    def find_vswhere_exe
      # Try the standard location first
      exe = @vswhere_path / "vswhere.exe"
      if File.exists?(exe)
        Log.info { "Found vswhere.exe at standard location: #{exe}" }
        return exe
      end
      
      # Try to find it in PATH
      exe_path = Process.find_executable("vswhere")
      if exe_path
        Log.info { "Found vswhere in PATH at: #{exe_path}" }
        return Path.new(exe_path)
      end
      
      # Try other common locations
      alternate_locations = [
        @program_files.join("Microsoft Visual Studio/Installer/vswhere.exe"),
        Path.new("C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"),
        Path.new("C:/Program Files/Microsoft Visual Studio/Installer/vswhere.exe")
      ]
      
      alternate_locations.each do |location|
        if File.exists?(location)
          Log.info { "Found vswhere.exe at alternate location: #{location}" }
          return location
        end
      end
      
      Log.error { "vswhere.exe not found in any location" }
      nil
    end

    def update_env_path
      # Check if the environment is Windows.
      {% unless flag?(:windows) %}
        raise "This is not a Windows virtual environment!"
      {% end %}

      # Add the standard location of "vswhere" to PATH, if not already there.
      path = ENV["PATH"]? || ""
      path += ";" + vswhere_path.to_s unless path.includes?(vswhere_path.to_s)
      ENV["PATH"] = path
    end

    def vs_year_to_versionnumber(vsversion : String?) : String?
      vs_year_version[vsversion]?
    end

    def vsversion_to_year(vsversion : String) : String
      @vs_year_version.each do |year, version|
        return year.to_s if vsversion == version
      end
      "17.0"
    end

    def find_with_vswhere(pattern : String, version_pattern : String) : Path?
      return nil unless vswhere_exe
      
      exe = vswhere_exe.not_nil!.to_s
      Log.debug { "Using vswhere.exe at: #{exe}" }
      
      # Build the command arguments
      vswhere = ["/C", exe, "-products", "*"]
      
      # Handle version pattern properly
      if version_pattern == "-latest"
        vswhere << "-latest"
      elsif version_pattern.starts_with?("-version")
        # Extract the version string and add it properly
        if version_pattern =~ /-version\s+"([^"]+)"/
          version_str = $1
          vswhere << "-version" << version_str
        else
          # Fallback if regex doesn't match
          version_pattern.split(' ', remove_empty: true).each do |part|
            vswhere << part
          end
        end
      else
        vswhere << version_pattern
      end
      
      vswhere << "--prerelease" if version_pattern.includes?(',')
      vswhere.concat %w(-property installationPath -sort -utf8)

      Log.debug { "Running vswhere command: cmd #{vswhere.join(" ")}" }
      
      io_out = IO::Memory.new
      io_error = IO::Memory.new

      result = Process.run(command: "cmd", args: vswhere, output: io_out, error: io_error)

      cmd_output_string = io_out.to_s
      cmd_error_string = io_error.to_s

      # Print debug information
      Log.info { "vswhere command output: #{cmd_output_string.inspect}" }
      Log.error { "vswhere command error: #{cmd_error_string.inspect}" } unless cmd_error_string.empty?

      paths = cmd_output_string.lines.reject(&.empty?)
      
      if paths.empty?
        Log.warn { "No Visual Studio installations found by vswhere" }
        return nil
      end
      
      path = paths.first

      if path.includes?("Visual Studio Locator") || path.includes?("Copyright (C)")
        Log.error { "Query to vswhere failed: #{path}" }
        return nil
      end

      res = Path.new(path).join(pattern).normalize
      
      if File.exists?(res)
        Log.info { "Found #{pattern} at: #{res}" }
        return res
      else
        Log.warn { "Path found by vswhere doesn't exist: #{res}" }
        return nil
      end
    end

    def find_vcvarsall(vsversion : String? = nil) : Path
      Log.info { "Looking for vcvarsall.bat with vsversion: #{vsversion.inspect}" }
      
      vsversion_number = vs_year_to_versionnumber(vsversion)
      Log.debug { "Converted to version number: #{vsversion_number.inspect}" }
      
      version_pattern =
        if vsversion_number
          vsversion_number = vsversion_number.not_nil!
          if vsversion_number.includes?(".")
            %(-version "#{vsversion_number}")
          else
            if vsversion
              upper_bound_stem = vsversion.to_s.split(".")[0]
              %(-version "#{vsversion_number},#{upper_bound_stem}.9")
            else
              "-latest"
            end
          end
        else
          "-latest"
        end
      
      Log.debug { "Using version pattern: #{version_pattern}" }

      # Try to find using vswhere first
      if vswhere_exe
        Log.info { "Trying to find with vswhere..." }
        if path = find_with_vswhere("VC/Auxiliary/Build/vcvarsall.bat", version_pattern)
          Log.info { "Found with vswhere: #{path}" }
          return path
        else
          Log.warn { "Not found with vswhere, trying standard locations" }
        end
      else
        Log.warn { "vswhere.exe not available, trying standard locations" }
      end

      # Try standard locations based on Visual Studio version
      Log.info { "Searching in standard locations..." }
      vs_year_version.each do |ver, _|
        EDITIONS.each do |ed|
          path = program_files.join("Microsoft Visual Studio", ver, ed, "VC/Auxiliary/Build/vcvarsall.bat")
          Log.debug { "Trying standard location: #{path}" }
          if File.exists?(path)
            Log.info { "Found in standard location: #{path}" }
            return path.normalize
          end
        end
      end

      Log.warn { "Not found in standard locations, trying VS 2015 location" }

      # Try VS 2015 location
      path = program_files_x86.join("Microsoft Visual C++ Build Tools/vcbuildtools.bat")
      if File.exists?(path)
        Log.info { "Found VS 2015: #{path}" }
        return path.normalize
      end

      Log.error { "Not found in VS 2015 location: #{path}" }

      # Try additional fallback locations
      fallback_locations = [
        program_files.join("Microsoft Visual Studio/2022/BuildTools/VC/Auxiliary/Build/vcvarsall.bat"),
        program_files.join("Microsoft Visual Studio/2019/BuildTools/VC/Auxiliary/Build/vcvarsall.bat"),
        program_files.join("Microsoft Visual Studio/2017/BuildTools/VC/Auxiliary/Build/vcvarsall.bat"),
        program_files_x86.join("Microsoft Visual Studio/2022/BuildTools/VC/Auxiliary/Build/vcvarsall.bat"),
        program_files_x86.join("Microsoft Visual Studio/2019/BuildTools/VC/Auxiliary/Build/vcvarsall.bat"),
        program_files_x86.join("Microsoft Visual Studio/2017/BuildTools/VC/Auxiliary/Build/vcvarsall.bat")
      ]

      Log.info { "Trying fallback locations..." }
      fallback_locations.each do |loc|
        Log.debug { "Checking fallback location: #{loc}" }
        if File.exists?(loc)
          Log.info { "Found in fallback location: #{loc}" }
          return loc
        end
      end

      # If we get here, we couldn't find Visual Studio
      error_msg = "Microsoft Visual Studio not found. Please install Visual Studio with C++ development tools."
      Log.error { error_msg }
      raise error_msg
    end

    def pathbuf_from_key(key : String) : Path
       v = ENV[key]
         Path.new(v)
    rescue ex
       Log.warn{ "error getting ENV[#{key}]"}
       raise ex
    
    end
  end
end

# def self.find_with_vswhere(pattern : String, version_pattern : String) : Path
#   vswhere = %W[
#     vswhere
#     -products
#     *
#     #{version_pattern}
#     -property
#     installationPath
#     -sort
#     -utf8
#   ].join(" ")

#   tmp_batch = Tempfile.open("vswhere", "w") do |batch|
#     batch.puts vswhere
#     batch.path
#   end

#   cmd = IO::Process.new("cmd", %W[/C #{tmp_batch}])
#   result = cmd.read_to_end

#   paths = result.to_s.trim.split('\n')[1..-1]
#   path = paths[0] if paths[0]

#   raise "Couldn't determine the latest VS installation path" unless path

#   path = path.trim

#   raise "Query to vswhere failed:\n\t#{path}" if path =~ /Visual Studio Locator|Copyright \(C\)/

#   %canonicalize(Path.new(path).join(pattern))
# end
