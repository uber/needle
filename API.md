Needle API
==========
This document will explain the Needle API and what classes one uses to interact with Needle in your code.

1. [Introduction and Terminology](#intro)
2. [Components](#components)
3. [Dependencies](#dependencies)
4. [Using the Component](#using)
4. [Tree-structure](#tree)

# Introduction and Terminology

## Basics
The primary reasons to use Dependency Injection (DI, from this point forward) is explained in a separate [doc](./WHY_DI.md). Please read that before proceeding if you're unsure whether your application can benefit from DI.

## Key pieces
At the very core, there's really just one class to master -- the `Component`. At Uber every `RIB` in the app has a `Component` subclass to go with it. As we'd like this tutorial to be broadly applicable, from this point on, we'll just assume we're talking about a classic `MVC` app (**Note:** This is why our sample apps use `MVC` instead of our own [`RIB`](https://github.com/uber/RIBs) architecture).

So for every `UIViewController` in your app, you would typically have a `Component` subclass to go with it. In our apps, we typically have a `RootComponent`, `MainComponent`, `RideComponent`, and so on. Each *instance* of a `ViewController` subclass typically has it's own instance of the `Component` subclass that it is paired with. **Note:** A lot of the terminology used in conjunction with Needle is inspired by the Dagger DI system on Android.

# Components

Each `Component` is considered to be a `Scope`. The body of the component is relatively simple. It's typically a few variables whose bodies are constructing new objects. Here's an example `Component`

```swift
import NeedleFoundation

class LoginComponent: Component<LoginDependency> {
    var tokenProvider: TokenProvider {
    	return TokenProviderImpl()
    }
    
    var loginViewController: UIViewController {
       return LoginViewController(tokenProvider: tokenProvider, button: okButton)
    }
    
    var okButton: UIButton {
       return shared { return UIButton() }
    }
}
```
**Note:** It's up to you to decide what items make sense on the *DI Graph* and which items can be just local properties in your `ViewController` subclass. Anything that you'd like to mock during a test needs to be passed in (as a protocol) as Swift lacks an `OCMock` like tool.

The `shared` construct in the example is a utility function we provide (in the `Component` base class) that simply returns the same instance every time this `var` is accessed (as opposed to the one above it, which returns a new instance each time).

It's also recommended that you use the component to also construct the `ViewController` that is paired with this component. As you can see in the example above, this allows us to pass in all the dependencies that the `ViewController` needs without the `ViewController` even being aware that you're using a DI system in your project. As noted in the "Benefits of DI" document, it's best to pass in protocols instead of concrete classes or structs.

# Dependencies

If components ended here, they would simply be a container to hold all the "dependencies" of each `ViewController`. This, in itself, is useful as it allows for better unit-tests for your `ViewController` class. Of course, `UIViewController` subclasses are often not easily unit-testable, which is why our RIB architecture (and many others) splits out the "business logic" into a separate class which is easily unit testable.

The real power comes from being able to fetch items from other `Components` as well. 

In order to do this, we specify the items we'd like to fetch from other components in a protocol referred to as a `Dependency Protocol`. At Uber, the dependency protocol associated with a `NameEntryComponent` would be called `NameEntryDependency`. Here is an example (**Note:** We've already used this protocol above in the generic parameter of `Component` class) :

```swift
protocol LoginDependency: Dependency {
	var imageCache: ImageCache { get }
	var networkService: NetworkService { get }
}
```

# Using the Component

The nice thing is that you're now ready to write and compile code even though you may not be ready to run the needle command-line code-generator tool. We've also not told the system which `Component` the `imageCache` and `networkService` are supposed to come from.

The example only uses items that are created at the current `Scope`. If we also wanted to pass items into our ViewController which we expect to fetch from other Scopes, then the loginViewController would look like:

```swift
var loginViewController: UIViewController {
   return LoginViewController(tokenProvider: tokenProvider, imageCache: dependency.imageCache, button: okButton)
}
```
So even though there may not be any class (yet) that conforms to your `LoginDependency` protocol, you can still (successfully) compile this file by simply assuming there will be.

# Tree-Structure

The final piece of the puzzle is the question of how we let the system know where the items we listed in the dependency protocol actually come from. All of the `Component` subclasses that we've created need to be connected together as a tree. This is done by letting the system know about parent-child relationships between all your Components. You specify these relationships by simply writing a constructor for a child component in the parent. This looks something like this:

```swift
class LoginComponent: Component {
    var tokenProvider: TokenProvider {
    	return TokenProviderImpl()
    }
    
	...
	
	// MARK: - Children
	
	var postLoginComponent: PostLoginComponent {
		return PostLoginComponent(parent: self)
	}
}
```
Once this tree structure has been declared in code, the needle command-line tool uses it to decide where the dependencies for a particular Scope come from. The algorithm is simple, for each item that this scope requires, we walk up the chain of parents. The "nearest parent" that is able to provide an item (we match both the name and the type of the variable declared in the dependency protocol), is the one we fetch that property from.

# Putting it all together

At this point, we've covered the key pieces of the Needle API. However, you may still have a lot of questions right now. For example 

- "If the ViewController is created in the Component, how does this happen in practice? Does the 'Parent' ViewController have a pointer to the child component and use it to create the child view-controller?" (*btw, the answer is yes*)
- or "When exactly is the child component instantiated and by whom?".

It's difficult for us to anticipate all of these questions, and this is where perusing the sample **TicTacToe** project provided should help answer most of these "how does it all fit together in practice" line of questions. Look for where the Components and ViewControllers are being instantiated. Also, look for what gets passed into the constructors of various classes.

Bootstrapping all this when your application starts is another big question. There are two important items to be aware of:

- You **must** call `registerProviderFactories` in your `AppDelegate` in order for the Needle runtime to work.
- Typically, you'll instantiate the `RootComponent` in your application delegate and use it to get a hold of the `rootViewController` to get things started.

Again, look in our sample's `AppDelegate.swift` to see how it's put together.

# Exceptions

Only after you have your project working and you feel like you have a good understanding of the Needle API and DI in general, would we suggest you try to break away from the recommendations/conventions above. For instance, we recommend each `ViewController` has a corresponding `Component`, but nothing in the API prevents you from sharing one `Component` subclasse between multiple ViewControllers.