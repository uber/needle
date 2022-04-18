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
import UIKit

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Traversal Helpers

private func parent1(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent
}

private func parent2(_ component: NeedleFoundation.Scope) -> NeedleFoundation.Scope {
    return component.parent.parent
}

// MARK: - Providers

private class GameDependency1ab5926a977f706d3195Provider: GameDependency {
    var mutableScoreStream: MutableScoreStream {
        return loggedInComponent.mutableScoreStream
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
private class ScoreSheetDependency97f2595a691a56781aaaProvider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInComponent.scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(loggedInComponent: LoggedInComponent) {
        self.loggedInComponent = loggedInComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent
private func factory3f7d60e2119708f293bac0d8c882e1e0d9b5eda1(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ScoreSheetDependency97f2595a691a56781aaaProvider(loggedInComponent: parent2(component) as! LoggedInComponent)
}
/// ^->RootComponent->LoggedInComponent->ScoreSheetComponent
private func factory3f7d60e2119708f293ba0b20504d5a9e5588d7b3(_ component: NeedleFoundation.Scope) -> AnyObject {
    return ScoreSheetDependency97f2595a691a56781aaaProvider(loggedInComponent: parent1(component) as! LoggedInComponent)
}
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


private func factoryEmptyDependencyProvider(_ component: NeedleFoundation.Scope) -> AnyObject {
    return EmptyDependencyProvider(component: component)
}

// MARK: - Registration
private func registerProviderFactory(_ componentPath: String, _ factory: @escaping (NeedleFoundation.Scope) -> AnyObject) {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: componentPath, factory)
}

private func register1() {
    registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent", factorycf9c02c4def4e3d508816cd03d3cf415b70dfb0e)
    registerProviderFactory("^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent", factory3f7d60e2119708f293bac0d8c882e1e0d9b5eda1)
    registerProviderFactory("^->RootComponent->LoggedInComponent->ScoreSheetComponent", factory3f7d60e2119708f293ba0b20504d5a9e5588d7b3)
    registerProviderFactory("^->RootComponent->LoggedOutComponent", factory1434ff4463106e5c4f1bb3a8f24c1d289f2c0f2e)
    registerProviderFactory("^->RootComponent->LoggedInComponent", factoryEmptyDependencyProvider)
    registerProviderFactory("^->RootComponent", factoryEmptyDependencyProvider)
}

public func registerProviderFactories() {
    register1()
}
