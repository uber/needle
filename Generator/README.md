# needle

## Installation

### Compiling from source:

First fetch the dependencies:

```
$ swift package fetch
```

You can then build from the command-line:

```
$ swift build
```

For a release build with static-linking (so you can share the binary):

```
$ swift build -c release -Xswiftc -static-stdlib
```

Or create an Xcode project and build using the IDE:

```
$ swift package generate-xcodeproj --xcconfig-overrides xcode.xcconfig 
```
Note: For now, the xcconfig is being used to pass in the DEBUG define.

### Debugging

Needle is intended to be heavily multi-threaded. This makes stepping through the code rather complicated. To simplify the debugging process, set the `SINGLE_THREADED` enviroment variable for your `Run` configuration in the Scheme Editor to `1' or `YES`.

