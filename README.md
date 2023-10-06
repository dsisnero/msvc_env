# msvc-dev-cmd

A Crystal program to run any command under the [Visual Studio Developer Command
Prompt](https://learn.microsoft.com/en-us/visualstudio/ide/reference/command-prompt-powershell)
of your choice.

This is a port of the rust program by amyspark: https://github.com/amyspark/msvc-dev-cmd
but designed for desktop use.

## Using

### CLI

```
Usage: msvc-env [OPTIONS] <PROGRAM> [ARGS]...

Arguments:
  <PROGRAM>  Name or path to the program I'll background to
  [ARGS]...  Arguments to the program

Options:
      --arch <ARCH>            Target architecture [default: x64]
      --sdk <SDK>              Windows SDK number to build for
      --spectre                Enable Spectre mitigations
      --toolset <TOOLSET>      VC++ compiler toolset version
      --uwp                    Build for Universal Windows Platform
      --vsversion <VSVERSION>  The Visual Studio version to use. This can be the version number (e.g. 16.0 for 2019) or the year (e.g. "2019")
  -h, --help                   Print help
  -V, --version                Print version
```
### Existing Crystal Project

Add the following to your `shard.yml` and run `shards install`.

```yaml
dependencies:
  msvc_env:
    github: dsisnero/msvc_env
    version: ~> 0.7
```

## Building

Just `shards build --release`.

## License

Mozilla Public License 2.0# msvc_env

## Contributing

1. Fork it (<https://github.com/dsisnero/msvc_env/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dsisnero](https://github.com/dsisnero) - creator and maintainer
