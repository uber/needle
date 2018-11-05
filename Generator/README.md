# Needle Code Generator

## Building and developing

### Compiling from source:

First resolve the dependencies:

```
$ swift package resolve
```

You can then build from the command-line:

```
$ swift build
```

Or create an Xcode project and build using the IDE:

```
$ swift package generate-xcodeproj --xcconfig-overrides xcode.xcconfig 
```
Note: For now, the xcconfig is being used to pass in the DEBUG define.

### Debugging

Needle is intended to be heavily multi-threaded. This makes stepping through the code rather complicated. To simplify the debugging process, set the `SINGLE_THREADED` enviroment variable for your `Run` configuration in the Scheme Editor to `1` or `YES`.

## Releasing

1. Compile a binary executable using the following command:

```
$ swift build -c release -Xswiftc -static-stdlib
```

2. Copy the resulting binary into the `Generator/bin/` folder, replacing the old binary.

3. Create a new release with the appropriate version number on [GitHub](https://github.com/uber/needle/releases). Make sure the binary executable is included, as an asset, in the GitHub release as well.
