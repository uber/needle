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

import Foundation

import XCTest
@testable import NeedleFramework

class DependencyProviderSerializerTaskTests: AbstractGeneratorTests {

    func test_execute_withSampleProject_verifySerialization() {
        let (components, imports) = sampleProjectParsed()
        for component in components {
            let providers = DependencyProviderDeclarerTask(component: component).execute()
            let processedProviders = DependencyProviderContentTask(providers: providers).execute()
            for provider in processedProviders {
                let serializedProviders = DependencyProviderSerializerTask(providers: [provider]).execute()
                XCTAssertEqual(serializedProviders.count, 1)
                verify(provider, against: serializedProviders[0])
            }
        }

        XCTAssertEqual(imports, ["import NeedleFoundation", "import RxSwift", "import UIKit"])
    }

    private func verify(_ provider: ProcessedDependencyProvider, against serializedProvider: SerializedProvider) {
        switch provider.unprocessed.pathString {
        case "^->RootComponent->LoggedInComponent->GameComponent":
            XCTAssertEqual(serializedProvider.registration, "__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent->GameComponent\") { component in\n    return GameDependency1ab5926a977f706d3195Provider(component: component)\n}\n")
            XCTAssertEqual(serializedProvider.content, "/// ^->RootComponent->LoggedInComponent->GameComponent\nprivate class GameDependency1ab5926a977f706d3195Provider: GameDependency {\n    var mutableScoreStream: MutableScoreStream {\n        return loggedInComponent.mutableScoreStream\n    }\n    var playersStream: PlayersStream {\n        return rootComponent.playersStream\n    }\n    private let loggedInComponent: LoggedInComponent\n    private let rootComponent: RootComponent\n    init(component: NeedleFoundation.ComponentType) {\n        loggedInComponent = component.parent as! LoggedInComponent\n        rootComponent = component.parent.parent as! RootComponent\n    }\n}\n")
        case "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent":
            XCTAssertEqual(serializedProvider.registration, "__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent\") { component in\n    return ScoreSheetDependency97f2595a691a56781aaaProvider(component: component)\n}\n")
            XCTAssertEqual(serializedProvider.content, "/// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent\nprivate class ScoreSheetDependency97f2595a691a56781aaaProvider: ScoreSheetDependency {\n    var scoreStream: ScoreStream {\n        return loggedInComponent.scoreStream\n    }\n    private let loggedInComponent: LoggedInComponent\n    init(component: NeedleFoundation.ComponentType) {\n        loggedInComponent = component.parent.parent as! LoggedInComponent\n    }\n}\n")
        case "^->RootComponent->LoggedInComponent->ScoreSheetComponent":
            XCTAssertEqual(serializedProvider.registration, "__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent->ScoreSheetComponent\") { component in\n    return ScoreSheetDependencycbd7fa4bae2ee69a1926Provider(component: component)\n}\n")
            XCTAssertEqual(serializedProvider.content, "/// ^->RootComponent->LoggedInComponent->ScoreSheetComponent\nprivate class ScoreSheetDependencycbd7fa4bae2ee69a1926Provider: ScoreSheetDependency {\n    var scoreStream: ScoreStream {\n        return loggedInComponent.scoreStream\n    }\n    private let loggedInComponent: LoggedInComponent\n    init(component: NeedleFoundation.ComponentType) {\n        loggedInComponent = component.parent as! LoggedInComponent\n    }\n}\n")
        case "^->RootComponent->LoggedOutComponent":
            XCTAssertEqual(serializedProvider.registration, "__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedOutComponent\") { component in\n    return LoggedOutDependencyacada53ea78d270efa2fProvider(component: component)\n}\n")
            XCTAssertEqual(serializedProvider.content, "/// ^->RootComponent->LoggedOutComponent\nprivate class LoggedOutDependencyacada53ea78d270efa2fProvider: LoggedOutDependency {\n    var mutablePlayersStream: MutablePlayersStream {\n        return rootComponent.mutablePlayersStream\n    }\n    private let rootComponent: RootComponent\n    init(component: NeedleFoundation.ComponentType) {\n        rootComponent = component.parent as! RootComponent\n    }\n}\n")
        case "^->RootComponent->LoggedInComponent":
            XCTAssertEqual(serializedProvider.registration, "__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent\") { component in\n    return EmptyDependencyProvider(component: component)\n}\n")
        case "^->RootComponent":
            XCTAssertEqual(serializedProvider.registration, "__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent\") { component in\n    return EmptyDependencyProvider(component: component)\n}\n")
        default:
            XCTFail("Unverified provider with path \(provider.unprocessed.pathString)")
        }
    }
}
