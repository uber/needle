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

// MARK: - Dependency Provider Factories

class NeedleGenerated {

    static func registerDependencyProviderFactories() {
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
            return RootComponentDependencyProvider()
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedOutComponent") { component in
            return LoggedOutComponentDependencyProvider(component: component)
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent") { component in
            return LoggedInComponentDependencyProvider()
        }
    }
}

// MARK: - Dependency Providers

private class RootComponentDependencyProvider: EmptyDependency {}

private class LoggedOutComponentDependencyProvider: LoggedOutDependency {
    var mutablePlayersStream: MutablePlayersStream {
        return rootComponent.mutablePlayersStream
    }
    private let rootComponent: RootComponent
    init(component: ComponentType) {
        let loggedOut = component as! LoggedOutComponent
        rootComponent = loggedOut.parent as! RootComponent
    }
}

private class LoggedInComponentDependencyProvider: EmptyDependency {}
