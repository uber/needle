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

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = "f7e65514498ad4f99ae8eb589dd36bbc"

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

private func parent2(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent
}

private func parent3(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent.parent
}

// MARK: - Providers

private class LoggedOutDependencyacada53ea78d270efa2fProvider: LoggedOutDependency {
    var mutablePlayersStream: MutablePlayersStream {
        return rootComponent.mutablePlayersStream
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LoggedOutComponent
private func factory1434ff4463106e5c4f1bb3a8f24c1d289f2c0f2e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return LoggedOutDependencyacada53ea78d270efa2fProvider(rootComponent: parent1(component) as! RootComponent)
}
private class ScoreSheetDependencyea879b8e06763171478bProvider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return (loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent).scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(loggedInComponent: LoggedInComponent) {
        self.loggedInComponent = loggedInComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent
private func factoryb11b7d1dec7e3c9b3dca49b41e44e0ed6a6f8eaf(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ScoreSheetDependencyea879b8e06763171478bProvider(loggedInComponent: parent3(component) as! LoggedInComponent)
}
private class ScoreSheetDependency6fb80fa6e1ee31d9ba11Provider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInNonCoreComponent.scoreStream
    }
    private let loggedInNonCoreComponent: LoggedInNonCoreComponent
    init(loggedInNonCoreComponent: LoggedInNonCoreComponent) {
        self.loggedInNonCoreComponent = loggedInNonCoreComponent
    }
}
/// ^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent
private func factory3306c50e89e2421d0b0c65d055996113f3c13de1(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ScoreSheetDependency6fb80fa6e1ee31d9ba11Provider(loggedInNonCoreComponent: parent1(component) as! LoggedInNonCoreComponent)
}
private class GameDependency1ab5926a977f706d3195Provider: GameDependency {
    var mutableScoreStream: MutableScoreStream {
        return loggedInComponent.pluginExtension.mutableScoreStream
    }
    var playersStream: PlayersStream {
        return rootComponent.playersStream
    }
    private let loggedInComponent: LoggedInComponent
    private let rootComponent: RootComponent
    init(loggedInComponent: LoggedInComponent, rootComponent: RootComponent) {
        self.loggedInComponent = loggedInComponent
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent
private func factorycf9c02c4def4e3d508816cd03d3cf415b70dfb0e(_ component: NeedleFoundation.Scope) -> AnyObject {
    return GameDependency1ab5926a977f706d3195Provider(loggedInComponent: parent1(component) as! LoggedInComponent, rootComponent: parent2(component) as! RootComponent)
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


private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

private func register1() {
    registerProviderFactory("^->RootComponent->LoggedOutComponent", factory1434ff4463106e5c4f1bb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent", factoryb11b7d1dec7e3c9b3dca49b41e44e0ed6a6f8eaf)
    registerProviderFactory("^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent", factory3306c50e89e2421d0b0c65d055996113f3c13de1)
    registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent", factorycf9c02c4def4e3d508816cd03d3cf415b70dfb0e)
    registerProviderFactory("^->RootComponent->LoggedInComponent", factoryEmptyDependencyProvider)
    __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "GameComponent") { component in
        return GamePluginExtensionProvider(component: component)
    }
    __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "LoggedInComponent") { component in
        return LoggedInPluginExtensionProvider(component: component)
    }
}

public func registerProviderFactories() {
    register1()
}
