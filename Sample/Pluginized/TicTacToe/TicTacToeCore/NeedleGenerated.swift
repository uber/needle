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

// MARK: - Dependency Provider Factories

func registerDependencyProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
        return GameDependency_2401566548657102800Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency_92930658912857926Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency_7465867243344110682Provider(component: component)
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
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
}

func registerPluginExtensionProviderFactories() {
    __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
        return GamePluginExtension4815886340652882587Provider(component: component)
    }
    __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "^->RootComponent->LoggedInComponent") { component in
        return LoggedInPluginExtension_2401566548657102800Provider(component: component)
    }
}

// MARK: - Dependency Providers

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
/// ^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent
private class ScoreSheetDependency_92930658912857926Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInNonCoreComponent.scoreStream
    }
    private let loggedInNonCoreComponent: LoggedInNonCoreComponent
    init(component: ComponentType) {
        let loggedInComponent = component.parent.parent.parent as! LoggedInComponent
        loggedInNonCoreComponent = loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent
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

// MARK: - Plugin Extension Providers

/// ^->RootComponent->LoggedInComponent
private class LoggedInPluginExtension_2401566548657102800Provider: LoggedInPluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder {
        return loggedInNonCoreComponent.scoreSheetBuilder
    }
    var mutableScoreStream: MutableScoreStream {
        return loggedInNonCoreComponent.mutableScoreStream
    }
    private unowned let loggedInNonCoreComponent: LoggedInNonCoreComponent
    fileprivate init(component: ComponentType) {
        let loggedInComponent = component as! LoggedInComponent
        loggedInNonCoreComponent = loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent
    }
}
/// ^->RootComponent->LoggedInComponent
private class GamePluginExtension4815886340652882587Provider: GamePluginExtension {
    var scoreSheetBuilder: ScoreSheetBuilder {
        return gameNonCoreComponent.scoreSheetBuilder
    }
    private unowned let gameNonCoreComponent: GameNonCoreComponent
    fileprivate init(component: ComponentType) {
        let gameComponent = component as! GameComponent
        gameNonCoreComponent = gameComponent.nonCoreComponent as! GameNonCoreComponent
    }
}
