import NeedleFoundation

// MARK: - Dependency Provider Factories

func registerDependencyProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
        return GameDependency_2401566548657102800Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency_1515114331612493672Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency8667150673442932147Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedOutComponent") { component in
        return LoggedOutDependency5490810220359560589Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    
}

// MARK: - Dependency Providers

/// ^->RootComponent->LoggedInComponent->GameComponent
private class GameDependency_2401566548657102800Provider: GameDependency {
    var mutableScoreStream: MutableScoreStream {
        return loggedInComponent.mutableScoreStream
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
/// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent
private class ScoreSheetDependency_1515114331612493672Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInComponent.scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(component: ComponentType) {
        loggedInComponent = component.parent.parent as! LoggedInComponent
    }
}
/// ^->RootComponent->LoggedInComponent->ScoreSheetComponent
private class ScoreSheetDependency8667150673442932147Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInComponent.scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(component: ComponentType) {
        loggedInComponent = component.parent as! LoggedInComponent
    }
}
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
