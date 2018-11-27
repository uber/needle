# Needle Tools

## Building and developing

First resolve the dependencies:

```
$ swift package update
$ carthage update
```

Create an Xcode project:

```
$ swift package generate-xcodeproj
```

Link Carthage frameworks

1. Drag and drop all frameworks from the `Carthage/Build/Mac/` folder into the `Frameworks` group in Xcode.
2. Add a `Copy Files` Build Phase to the `needletools` target. The `Destination` should be `Products Directory`. Add all the Carthage frameworks to phase.

## Releasing

1. Compile a binary executable using the following command:

```
$ swift build -c release -Xswiftc -static-stdlib
```

2. Copy the resulting binary into the `Tools/bin/` folder, replacing the old binary.

3. Create a PR with the new binary.
