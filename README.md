# msvc_env

A Crystal library to run any command under the [Visual Studio Developer Command
Prompt](https://learn.microsoft.com/en-us/visualstudio/ide/reference/command-prompt-powershell)
of your choice.

This is a port of the rust program by amyspark: https://github.com/amyspark/msvc-dev-cmd
but designed for desktop use.

## Installation

Add the following to your `shard.yml` and run `shards install`.

```yaml
dependencies:
  msvc_env:
    github: dsisnero/msvc_env
    version: ~> 0.7
```

## Usage

### Command Line

```bash
# Launch an interactive Visual Studio Developer Command Prompt
msvc-env

# Run a command with the default Visual Studio environment
msvc-env cmd /c echo "Hello from VS environment"

# Specify a particular Visual Studio version
msvc-env --version 2019 cmd /c echo "Hello from VS 2019"

# Specify architecture
msvc-env --arch x86 cmd /c echo "Using x86 architecture"

# Full options
msvc-env --arch x64 --sdk 10.0.19041.0 --toolset 14.29 --version 2022 cl /help
```

### Command Line Options

```
Usage: msvc_env [opts] [PROGRAM] [PROGRAM_OPTIONS]

Options:
  -a ARCH, --arch ARCH         Target architecture (default: x64)
      --sdk SDK                Windows SDK number to build for
      --toolset TOOLSET        VC++ compiler toolset version
      --version VERSION        The Visual Studio version to use (e.g., '16.0' for 2019)
  -h, --help                   Show this help message
```

### As a Library

```crystal
require "msvc_env"

# Run a command in the Visual Studio environment
controller = MsvcEnv::Controller.new
controller.msvc_env do
  # Inside this block, the VS environment is active
  system("cl /help")
end

# Run with specific options
options = MsvcEnv::Options.new
options.arch = "x86"
options.version = "2019"
options.program = "cl"
options.args = "/help"

controller = MsvcEnv::Controller.new
controller.run(options)

# Get environment variables
constants = MsvcEnv::Constants.new
vcvarsall_path = constants.find_vcvarsall("2022")
puts "Found vcvarsall.bat at: #{vcvarsall_path}"
```

## Debugging

Set the `DEBUG` environment variable to get detailed output:

```bash
set DEBUG=1
msvc-env cmd /c echo "Debug mode"
```

## Building

```bash
shards build --release
```

## License

MIT

## Contributing

1. Fork it (<https://github.com/dsisnero/msvc_env/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dsisnero](https://github.com/dsisnero) - creator and maintainer
