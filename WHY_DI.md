# Why use dependency injection?

This document describes the basics of the dependency injection pattern; what it is; and why it is a good pattern to apply to your app development? The texts below uses the term DI as short for dependency injection.

## A somewhat real example to illustrate

Instead of describing the pattern in abstract terms, let's use a simple view controller based example to understand it. If you are interested in an abstract description, Wikipedia has [a great article](https://en.wikipedia.org/wiki/Dependency_injection).

Let's say we are developing a photo browsing app, where we have a view controller that displays a set of photos retrieved from the server. In this extremely simple app, we have a `PhotosViewController` that displays the photos, and a `PhotosService` that encapsulates the logic of requesting photos from our server. The `PhotosViewController` implements the view logic while the `PhotosService` contains the HTTP request sending and response parsing logic.  Without using DI, our `PhotosViewController` would instantiate a new instance of the `PhotosService` in its `init` or `viewDidLoad` method. Then it can use the service object to request photos when it sees fit.

Now let's step back and analyze our code. In its current state, the `PhotosViewController` and `PhotosService` are tightly coupled. This leaves us with a few issues:
1. We cannot change `PhotosService` without having to also change `PhotosViewController`. This may seem fine with just two classes, but in a real-world scenario with hundreds of classes this would significantly slowdown our app iteration.
2. We cannot switch out the `PhotosService` class without having to change `PhotosViewController`. Let's imagine we have a better `PhotosServiceV2` class we now want our view controller to use, we'll have to dig into the implementation of `PhotosViewController` to make changes.
3. We cannot unit test `PhotosViewController` without also invoking the `PhotosService` implementation.
4. We cannot develop `PhotosViewController` independently and concurrently with the `PhotosService`. This may not seem like a big deal with our extremely simple app, in a real-world team, our engineers would be blocked constantly.

Let's apply the DI pattern to our app. With DI, we will have a third class, in Needle's terms a `Component` class, that instantiates the `PhotosService` and pass it into the `PhotosViewController` as a protocol. Let's call this protocol `PhotosServicing`. Now our `PhotosViewController` no longer knows anything about the concrete implementation of `PhotosService`. It simply uses the passed in `PhotosServicing` protocol to perform its logic.

With DI applied, let's revisit the issues we had before:
1. We can freely change the implementation of `PhotosService` without affecting our `PhotosViewController`.
2. We can simply update our DI `Component` class to instantiate and pass `PhotosServiceV2` into `PhotosViewController`, as long as the implementation still conforms to the `PhotosServicing` protocol. This allows us to freely switch implementations of the photos service without having to change anything in the view controller.
3. We can properly unit test `PhotosViewController` by injecting, aka passing in, a mock `PhotosServicing` object.
4. As soon as the `PhotosServicing` protocol is defined, we can independently and concurrently develop `PhotosService` and `PhotosViewController` implementations.

## Dependency injection terminologies

Before moving on, let's define some terminology that is frequently used with the DI pattern. In our example app above, the `PhotosService` is typically referred to as a "dependency". Our `PhotosViewController` class is sometimes referred to as the "dependent" or "consumer". The act of passing an instance of `PhotosServicing` into the `PhotosViewController` is called  "inject". In summary, our simple DI setup injects the `PhotosServicing` dependency into the consumer `PhotosViewController`. 
