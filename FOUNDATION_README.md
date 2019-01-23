# Needle Foundation Library

## Building and developing

First resolve the dependencies:

```
$ swift package update
```

You can then build from the command-line:

```
$ swift build
```

Or create an Xcode project and build using the IDE:

```
$ swift package generate-xcodeproj --xcconfig-overrides foundation.xcconfig
```
Note: For now, the xcconfig is being used to pass in the iOS deployment target settings.

**Once a Xcode project is generated using Swift Package Manager, the Xcode project's schemes must be recreated for both the `NeedleFoundation` framework as well as the `NeedleFoundationTests` test target.** This is required for Carthage and CI.
