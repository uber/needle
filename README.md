# Needle

[![Build Status](https://travis-ci.com/uber/needle.svg?branch=master)](https://travis-ci.com/uber/needle?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Needle is a dependency injection (DI) system for Swift. Unlike other DI frameworks, such as [Cleanse](https://github.com/square/Cleanse), [Swinject](https://github.com/Swinject/Swinject), Needle encourages **hierarchical DI structure and utilizes code generation to ensure compile-time safety**. This allows us to develop our apps and make changes with confidence. **If it compiles, it works.** In this aspect, Needle is more similar to [Android Dagger](https://google.github.io/dagger/).

## [Why use dependency injection?](./WHY_DI.md)

The linked document uses a somewhat real example to explain what the dependency injection pattern is, and its benefits.

## Installation

Needle has two parts, the `NeedleFoundation` framework and the executable code generator. Both parts need to be integrated with your Swift project in order to use Needle as your DI system.

#### Install `NeedleFoundation` framework via [Carthage](https://github.com/Carthage/Carthage)

Please follow the standard [Carthage installation process](https://github.com/Carthage/Carthage#quick-start) to integrate the `NeedleFoundation` framework with your Swift project.
```
github "https://github.com/uber/needle.git" ~> VERSION_OF_NEEDLE
```

#### Install `NeedleFoundation` framework via [CocoaPods](https://github.com/CocoaPods/CocoaPods)

Coming soon!

#### Install code generator via [Carthage](https://github.com/Carthage/Carthage)

If Carthage is used to integrate  the `NeedleFoundation` framework, then a copy of the code generator executable of the corresponding version is already downloaded in the Carthage folder. It can be found at `Carthage/Checkouts/needle/Generator/bin/needle`.

#### Install code generator via [Homebrew](https://github.com/Homebrew/brew)

Coming soon!

## Getting started with Needle

Using and integrating with Needle has three steps. Each of the following steps has detailed instructions and explanations in the linked documents.

1. [Integrate Needle's code generator with your Swift project](./GENERATOR.md).
2. [Write application DI code following NeedleFoundation's API](./API.md).

## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency?ref=badge_large)
