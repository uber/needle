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
import SwiftUI
import UIKit

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Registration

public func registerProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
        return GameDependency1ab5926a977f706d3195Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependency97f2595a691a56781aaaProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->ScoreSheetComponent") { component in
        return ScoreSheetDependencycbd7fa4bae2ee69a1926Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedOutComponent") { component in
        return LoggedOutDependencyacada53ea78d270efa2fProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    
}

// MARK: - Providers

private class GameDependency1ab5926a977f706d3195BaseProvider: GameDependency {
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
private class GameDependency1ab5926a977f706d3195Provider: GameDependency1ab5926a977f706d3195BaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(loggedInComponent: component.parent as! LoggedInComponent, rootComponent: component.parent.parent as! RootComponent)
    }
}
private class ScoreSheetDependency97f2595a691a56781aaaBaseProvider: ScoreSheetDependency {
    var scoreStream: ScoreStream {
        return loggedInComponent.scoreStream
    }
    private let loggedInComponent: LoggedInComponent
    init(loggedInComponent: LoggedInComponent) {
        self.loggedInComponent = loggedInComponent
    }
}
/// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent
private class ScoreSheetDependency97f2595a691a56781aaaProvider: ScoreSheetDependency97f2595a691a56781aaaBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(loggedInComponent: component.parent.parent as! LoggedInComponent)
    }
}
/// ^->RootComponent->LoggedInComponent->ScoreSheetComponent
private class ScoreSheetDependencycbd7fa4bae2ee69a1926Provider: ScoreSheetDependency97f2595a691a56781aaaBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(loggedInComponent: component.parent as! LoggedInComponent)
    }
}
private class LoggedOutDependencyacada53ea78d270efa2fBaseProvider: LoggedOutDependency {
    var mutablePlayersStream: MutablePlayersStream {
        return rootComponent.mutablePlayersStream
    }
    private let rootComponent: RootComponent
    init(rootComponent: RootComponent) {
        self.rootComponent = rootComponent
    }
}
/// ^->RootComponent->LoggedOutComponent
private class LoggedOutDependencyacada53ea78d270efa2fProvider: LoggedOutDependencyacada53ea78d270efa2fBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(rootComponent: component.parent as! RootComponent)
    }
}
