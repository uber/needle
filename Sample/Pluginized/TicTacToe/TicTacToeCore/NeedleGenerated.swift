//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import NeedleFoundation
import RxSwift
import ScoreSheet
import TicTacToeIntegrations
import UIKit

// MARK: - Registration

public func registerProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedOutComponent") { component in
        return LoggedOutDependencyacada53ea78d270efa2fProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependencyea879b8e06763171478bProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency6fb80fa6e1ee31d9ba11Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
        return GameDependency1ab5926a977f706d3195Provider(component: component)
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
private class LoggedOutDependencyacada53ea78d270efa2fProvider: LoggedOutDependency {
    var mutablePlayersStream: MutablePlayersStream {
        return rootComponent.mutablePlayersStream
    }
    private let rootComponent: RootComponent
    init(component: NeedleFoundation.Scope) {
        rootComponent = component.parent as! RootComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent
private class ScoreSheetDependencyea879b8e06763171478bProvider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return (loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent).scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(component: NeedleFoundation.Scope) {
        loggedInComponent = component.parent.parent.parent as! LoggedInComponent
    }
}
/// ^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent
private class ScoreSheetDependency6fb80fa6e1ee31d9ba11Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInNonCoreComponent.scoreStream
    }
    private let loggedInNonCoreComponent: LoggedInNonCoreComponent
    init(component: NeedleFoundation.Scope) {
        loggedInNonCoreComponent = component.parent as! LoggedInNonCoreComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent
private class GameDependency1ab5926a977f706d3195Provider: GameDependency {
    var mutableScoreStream: MutableScoreStream {
        return loggedInComponent.pluginExtension.mutableScoreStream
    }
    var playersStream: PlayersStream {
        return rootComponent.playersStream
    }
    private let loggedInComponent: LoggedInComponent
    private let rootComponent: RootComponent
    init(component: NeedleFoundation.Scope) {
        loggedInComponent = component.parent as! LoggedInComponent
        rootComponent = component.parent.parent as! RootComponent
    }
}
/// GameComponent plugin extension
private class GamePluginExtensionProvider: GamePluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder {
        return gameNonCoreComponent.scoreSheetBuilder
    }
    private unowned let gameNonCoreComponent: GameNonCoreComponent
    init(component: NeedleFoundation.Scope) {
        let gameComponent = component as! GameComponent
        gameNonCoreComponent = gameComponent.nonCoreComponent as! GameNonCoreComponent
    }
}
/// LoggedInComponent plugin extension
private class LoggedInPluginExtensionProvider: LoggedInPluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder {
        return loggedInNonCoreComponent.scoreSheetBuilder
    }
    var mutableScoreStream: MutableScoreStream {
        return loggedInNonCoreComponent.mutableScoreStream
    }
    private unowned let loggedInNonCoreComponent: LoggedInNonCoreComponent
    init(component: NeedleFoundation.Scope) {
        let loggedInComponent = component as! LoggedInComponent
        loggedInNonCoreComponent = loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent
    }
}
