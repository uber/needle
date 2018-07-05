import NeedleFoundation
import RxSwift
import ScoreSheet
import TicTacToeIntegrations
import UIKit

// MARK: - Registration

func registerProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedOutComponent") { component in
        return LoggedOutDependency5490810220359560589Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency_92930658912857926Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency_7465867243344110682Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
        return GameDependency_2401566548657102800Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "GameComponent") { component in
        return GamePluginExtensionProvider(component: component)
    }
    __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "LoggedInComponent") { component in
        return LoggedInPluginExtensionProvider(component: component)
    }
    
}

// MARK: - Providers

/// ^->RootComponent->LoggedOutComponent
private class LoggedOutDependency5490810220359560589Provider: LoggedOutDependency {
    var mutablePlayersStream: MutablePlayersStream {
        return rootComponent.mutablePlayersStream
    }
    private let rootComponent: RootComponent
    init(component: ComponentType) {
        rootComponent = component.parent as! RootComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent
private class ScoreSheetDependency_92930658912857926Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return (loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent).scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(component: ComponentType) {
        loggedInComponent = component.parent.parent.parent as! LoggedInComponent
    }
}
/// ^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent
private class ScoreSheetDependency_7465867243344110682Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInNonCoreComponent.scoreStream
    }
    private let loggedInNonCoreComponent: LoggedInNonCoreComponent
    init(component: ComponentType) {
        loggedInNonCoreComponent = component.parent as! LoggedInNonCoreComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent
private class GameDependency_2401566548657102800Provider: GameDependency {
    var mutableScoreStream: MutableScoreStream {
        return loggedInComponent.pluginExtension.mutableScoreStream
    }
    var playersStream: PlayersStream {
        return rootComponent.playersStream
    }
    private let loggedInComponent: LoggedInComponent
    private let rootComponent: RootComponent
    init(component: ComponentType) {
        loggedInComponent = component.parent as! LoggedInComponent
        rootComponent = component.parent.parent as! RootComponent
    }
}
/// GameComponent
private class GamePluginExtensionProvider: GamePluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder {
        return gameNonCoreComponent.scoreSheetBuilder
    }
    private unowned let gameNonCoreComponent: GameNonCoreComponent
    init(component: ComponentType) {
        let gameComponent = component as! GameComponent
        gameNonCoreComponent = gameComponent.nonCoreComponent as! GameNonCoreComponent
    }
}
/// LoggedInComponent
private class LoggedInPluginExtensionProvider: LoggedInPluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder {
        return loggedInNonCoreComponent.scoreSheetBuilder
    }
    var mutableScoreStream: MutableScoreStream {
        return loggedInNonCoreComponent.mutableScoreStream
    }
    private unowned let loggedInNonCoreComponent: LoggedInNonCoreComponent
    init(component: ComponentType) {
        let loggedInComponent = component as! LoggedInComponent
        loggedInNonCoreComponent = loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent
    }
}
