# Sample App Using Needle

The folder "MVC-rx" contains the simple MVC architecture based TicTacToe app using the reactive approach (RxSwift) while "MVC-plain" contains its non-reactive implementation. The folder "Pluginized" contains the same TicTacToe app but built with a pluginized DI structure where the dependencies are divided into separate core and non-core trees.

## Build & Run TicTacToe

Make sure [Carthage](https://github.com/Carthage/Carthage) is installed.

```
$ carthage update --platform ios
```

Open the TicTacToe.xcodeproj to build and run the game.
