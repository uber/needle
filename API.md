Needle API
==========
This document will explain the Needle API and what classes one uses to interact with Needle in your code.

1. [Introduction and Terminology](#introduction-and-terminology)
2. [Components](#components)
3. [Dependencies](#dependencies)
4. [Using the Component](#using-the-component)
4. [Tree-structure](#tree-structure)

# Installation

## Using [Carthage](https://github.com/Carthage/Carthage)

Please follow the standard [Carthage installation process](https://github.com/Carthage/Carthage#quick-start) to integrate the `NeedleFoundation` framework with your Swift project.
```
github "https://github.com/uber/needle.git" ~> VERSION_OF_NEEDLE
```

## Using [Swift Package Manager](https://github.com/apple/swift-package-manager)

Please specify Needle as a dependency via the standard [Swift Package Manager package definition process](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md) to integrate the `NeedleFoundation` framework with your Swift project.
```
dependencies: [
    .package(url: "https://github.com/uber/needle.git", .upToNextMajor(from: "VERSION_NUMBER")),
],
targets: [
    .target(
        name: "YOUR_MODULE",
        dependencies: [
            "NeedleFoundation",
        ]),
],
```

# Introduction and Terminology

## Basics
The primary reasons to use Dependency Injection (DI, from this point forward) is explained in a separate [doc](./WHY_DI.md). Please read that before proceeding if you're unsure whether your application can benefit from DI.

## Key pieces
At the very core, there's really just one class to master -- the `Component`. Needle can be used for any application which has a hierarchical structure. For the purposes of this tutorial, we'll assume we're talking about a classic `MVC` app (We use `UIViewController` in the text, but everything should easily apply to an `NSViewController` or equivalent concept from an architecture different from `MVC`).

So, for every `UIViewController` in your app, you would typically have a `Component` subclass to go with it. For a class called `WelcomeViewController` the component is typically named `WelcomeComponent`.

# Components

Each `Component` is considered to be a `Scope`. The body of the component is relatively simple. It's typically a few computed properties whose bodies are constructing new objects. Here's an example `Component`:

```swift
import NeedleFoundation

class LoggedInComponent: Component<LoggedInDependency> {
    var scoreStream: ScoreStream {
        return mutableScoreStream
    }

    var mutableScoreStream: MutableScoreStream {
        return shared { ScoreStreamImpl() }
    }

    var loggedInViewController: UIViewController {
        return LoggedInViewController(gameBuilder: gameComponent, scoreStream: scoreStream, scoreSheetBuilder: scoreSheetComponent)
    }
}
```
**Note:** It's up to you to decide what items make sense on the *DI Graph* and which items can be just local properties in your `ViewController` subclass. Anything that you'd like to mock during a test needs to be passed in (as a protocol) as Swift lacks an `OCMock` like tool.

The `shared` construct in the example is a utility function we provide (in the `Component` base class) that simply returns the same instance every time this `var` is accessed (as opposed to the one below it, which returns a new instance each time). This ties the lifecycle of this property to the lifecycle of the Component.

You could also use the component to construct the `ViewController` that is paired with this component. As you can see in the example above, this allows us to pass in all the dependencies that the `ViewController` needs without the `ViewController` even being aware that you're using a DI system in your project. As noted in the "Benefits of DI" document, it's best to pass in protocols instead of concrete classes or structs.

# Dependencies

If components ended here, they would simply be a container to hold all the "dependencies" of each `ViewController`. This, in itself, is useful as it allows for better unit-tests for your `ViewController` class. Of course, `UIViewController` subclasses are often not easily unit-testable, which is why our RIB architecture (and many others) splits out the "business logic" into a separate class which is easily unit testable.

The real power comes from being able to fetch items from ancestor `Components` within the same tree as well.

In order to do this, we specify the dependencies we'd like to fetch from ancestor components in a protocol referred to as a `Dependency Protocol`. At Uber, the dependency protocol associated with a `NameEntryComponent` would be called `NameEntryDependency`. Here is an example (**Note:** We've already used this protocol above in the generic parameter of `Component` class) :

```swift
protocol LoggedInDependency: Dependency {
    var imageCache: ImageCache { get }
    var networkService: NetworkService { get }
}
```

# Using the Component

The nice thing is that you're now ready to write and compile code even though you may not be ready to run the needle command-line code-generator tool. We've also not told the system which ancestor `Component` the `imageCache` and `networkService` are supposed to come from.

The example only uses items that are created at the current `Scope`. If we also wanted to pass items into our ViewController which we expect to fetch from other Scopes, then the loginViewController would look like:

```swift
    var loginViewController: UIViewController {
        return LoggedInViewController(gameBuilder: gameComponent, scoreStream: scoreStream, scoreSheetBuilder: scoreSheetComponent, imageCache: dependency.imageCache)
    }
```

# Tree-Structure

The final piece of the puzzle is the question of how we let the system know where the items we listed in the dependency protocol actually come from. All of the `Component` subclasses that we've created need to be connected together as a tree. This is done by letting the system know about parent-child relationships between all your Components. You specify these relationships by simply writing a constructor for a child component in the parent. This looks something like this:

```swift
class LoggedInComponent: Component {

    ...

    var loginViewController: UIViewController {
        return LoggedInViewController(gameBuilder: gameComponent, scoreStream: scoreStream, scoreSheetBuilder: scoreSheetComponent, imageCache: dependency.imageCache)
    }

    // MARK: - Children

    var gameComponent: GameComponent {
    	return GameComponent(parent: self)
    }
}
```
Once this tree structure has been declared in code, the needle command-line tool uses it to decide where the dependencies for a particular Scope come from. The algorithm is simple, for each item that this scope requires, we walk up the chain of parents. The **nearest parent** that is able to provide an item (we match both the name and the type of the variable declared in the dependency protocol), is the one we fetch that property from.

# Bootstrap Root

Since the root of a DI tree does not have a parent component, we bootstrap the root scope using the special `BootstrapComponent` class
```swift
let rootComponent = RootComponent()

class RootComponent: NeedleFoundation.RootComponent {
    /// Root component code...
}
```
Notice the `RootComponent` does not need to specify any dependency protocol by inheriting from `NeedleFoundation.RootComponent`. Root of a DI graph has no parent to acquire dependencies from anyways.

Since we know `root` does not have any parents, in application code, we can simply invoke `RootComponent()` to instantiate the root scope.

# Flexibility

Only after you have your project working and you feel like you have a good understanding of the Needle API and DI in general, would we suggest you try to break away from the recommendations/conventions above. For instance, we recommend each `ViewController` has a corresponding `Component`, but nothing in the API prevents you from sharing one `Component` subclass between multiple ViewControllers.
