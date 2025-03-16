# Helper module for debugging Crystal programs on Windows
module DebugHelper
  VERSION = "0.1.0"

  # Print detailed system information
  def self.print_system_info
    puts "=== System Information ==="
    puts "OS: #{ENV["OS"]? || "Unknown"}"
    puts "PROCESSOR_ARCHITECTURE: #{ENV["PROCESSOR_ARCHITECTURE"]? || "Unknown"}"
    puts "ProgramFiles: #{ENV["ProgramFiles"]? || "Unknown"}"
    puts "ProgramFiles(x86): #{ENV["ProgramFiles(x86)"]? || "Unknown"}"
    puts "PATH: #{ENV["PATH"]? || "Unknown"}"
    puts "TEMP: #{ENV["TEMP"]? || "Unknown"}"
    puts "=========================="
  end

  # Check if Visual Studio is installed
  def self.check_visual_studio
    puts "=== Visual Studio Check ==="
    vs_locations = [
      "C:/Program Files/Microsoft Visual Studio",
      "C:/Program Files (x86)/Microsoft Visual Studio"
    ]
    
    found = false
    vs_locations.each do |loc|
      if Dir.exists?(loc)
        puts "Found Visual Studio directory at: #{loc}"
        found = true
        # List subdirectories
        begin
          Dir.children(loc).each do |child|
            puts "  - #{child}"
          end
        rescue ex
          puts "  Error listing subdirectories: #{ex.message}"
        end
      end
    end
    
    unless found
      puts "No Visual Studio installation directories found"
    end
    puts "=========================="
  end

  # Check for vswhere.exe
  def self.check_vswhere
    puts "=== vswhere.exe Check ==="
    vswhere_locations = [
      "C:/Program Files/Microsoft Visual Studio/Installer/vswhere.exe",
      "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
    ]
    
    found = false
    vswhere_locations.each do |loc|
      if File.exists?(loc)
        puts "Found vswhere.exe at: #{loc}"
        found = true
      end
    end
    
    # Check in PATH
    if exe_path = Process.find_executable("vswhere")
      puts "Found vswhere in PATH at: #{exe_path}"
      found = true
    end
    
    unless found
      puts "vswhere.exe not found in any standard location"
    end
    puts "=========================="
  end

  # Run all checks
  def self.run_diagnostics
    print_system_info
    check_visual_studio
    check_vswhere
  end
end
