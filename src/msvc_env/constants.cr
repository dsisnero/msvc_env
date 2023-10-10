require "set"
require "hash"

module MsvcEnv
  struct Constants
    EDITIONS = ["Enterprise", "Professional", "Community", "Preview", "BuildTools"]
    property program_files_x86 : Path
    property program_files : Path
    getter vs_year_version : Hash(String, String)
    property vswhere_path : Path
    getter vswhere_exe : Path?

    def initialize
      @vs_year_version = Hash{
        "2022" => "17.0",
        "2019" => "16.0",
        "2017" => "15.0",
        "2015" => "14.0",
        "2013" => "12.0",
      }
      @program_files_x86 = pathbuf_from_key("ProgramFiles(x86)")
      @program_files = pathbuf_from_key("ProgramFiles")
      @vswhere_path = @program_files_x86.join("Microsoft Visual Studio/Installer").normalize
      @vswhere_exe = find_vswhere_exe
    end

    def find_vswhere_exe
      exe = @vswhere_path / "vswhere.exe"
      return exe if File.exists? exe
      exe = Process.find_executable("vswhere")
      Path.new exe if exe
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

    def vsversion_to_versionnumber(vsversion : String?) : String?
      vs_year_version[vsversion]?
    end

    def vsversion_to_year(vsversion : String) : String
      @vs_year_version.each do |year, version|
        return year.to_s if vsversion == version
      end
      "17.0"
    end

    def find_with_vswhere(pattern : String, version_pattern : String) : Path
      raise "vshere not found" unless vswhere_exe
      exe = vswhere_exe.not_nil!.to_s
      vswhere = ["/C", exe,
                 "-products", "*",
                 version_pattern,
      ]
      vswhere << "--prerelease" if version_pattern.includes?(',')
      vswhere.concat %w(-property installationPath -sort -utf8)

      io_out = IO::Memory.new
      io_error = IO::Memory.new

      result = Process.run(command: "cmd", args: vswhere, output: io_out, error: io_error)

      cmd_output_string = io_out.to_s
      cmd_error_string = io_error.to_s

      paths = cmd_output_string.lines
      path = paths.first || raise("Couldn't determine the latest VS installation path")

      if path.includes?("Visual Studio Locator") || path.includes?("Copyright (C)")
        raise "Query to vswhere failed:\n\t#{path}"
      end

      res = Path.new(path).join(pattern).normalize
      res
    end

    def find_vcvarsall(vsversion : String? = nil) : Path
      vsversion_number = vsversion_to_versionnumber(vsversion)
      version_pattern =
        if vsversion_number
          vsversion_number = vsversion_number.not_nil!
          if vsversion_number.includes?(".")
            %(-version "#{vsversion_number}")
          else
            if vsversion
              upper_bound_stem = vsversion.split(".")[0]
              %(-version "#{vsversion_number},#{upper_bound_stem}.9")
            else
              "-latest"
            end
          end
        else
          "-latest"
        end

      begin
        return find_with_vswhere("VC/Auxiliary/Build/vcvarsall.bat", version_pattern)
      rescue ex : Exception
        STDERR.puts "Not found with vswhere: #{ex}"
      end

      vs_year_version.each do |ver, _|
        EDITIONS.each do |ed|
          path = program_files.join("Microsoft Visual Studio", ver, ed, "VC/Auxiliary/Build/vcvarsall.bat")
          # puts "Trying standard location: #{path}"
          if File.exists? path
            puts "Found standard location: #{path}"
            return path.normalize
          end
        end
      end

      STDERR.puts "Not found in standard locations"

      path = program_files_x86.join("Microsoft Visual C++ Build Tools/vcbuildtools.bat")

      if File.exists? path
        puts "Found VS 2015: #{path}"
        return path.normalize
      end

      STDERR.puts "Not found in VS 2015 location: #{path}"

      raise "Microsoft Visual Studio not found"
    end

    def pathbuf_from_key(key : String) : Path
      v = ENV[key]
      Path.new(v)
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
