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

class PluginizedPropertiesSerializerTests: AbstractPluginizedGeneratorTests {

    func test_execute_withSampleProject_verifySerialization() {
        let (components, pluginizedComponents, _, _) = pluginizedSampleProjectParsed()
        for component in components {
            let providers = DependencyProviderDeclarerTask(component: component).execute()
            let processedProviders = try! PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents).execute()
            for provider in processedProviders {
                if provider.processedProperties.isEmpty {
                    continue
                }
                let serializedProperties = PluginizedPropertiesSerializer(provider: provider).serialize()

                switch provider.data.unprocessed.pathString {
                case "^->RootComponent->LoggedOutComponent":
                    XCTAssertEqual(serializedProperties, "    var mutablePlayersStream: MutablePlayersStream {\n        return rootComponent.mutablePlayersStream\n    }")
                case "^->RootComponent->LoggedInComponent->GameComponent->GameNonCoreComponent->ScoreSheetComponent":
                    XCTAssertEqual(serializedProperties, "    var scoreStream: ScoreStream {\n        return (loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent).scoreStream\n    }")
                case "^->RootComponent->LoggedInComponent->LoggedInNonCoreComponent->ScoreSheetComponent":
                    XCTAssertEqual(serializedProperties, "    var scoreStream: ScoreStream {\n        return loggedInNonCoreComponent.scoreStream\n    }")
                default:
                    XCTFail("Unverified provider path: \(provider.data.unprocessed.pathString)")
                }
            }
        }

        for pluginizedComponent in pluginizedComponents {
            let providers = DependencyProviderDeclarerTask(component: pluginizedComponent.data).execute()
            let processedProviders = try! PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents).execute()
            for provider in processedProviders {
                let serializedProperties = PluginizedPropertiesSerializer(provider: provider).serialize()

                switch provider.data.unprocessed.pathString {
                case "^->RootComponent->LoggedInComponent->GameComponent":
                    XCTAssertEqual(serializedProperties, "    var mutableScoreStream: MutableScoreStream {\n        return loggedInComponent.pluginExtension.mutableScoreStream\n    }\n    var playersStream: PlayersStream {\n        return rootComponent.playersStream\n    }")
                case "^->RootComponent->LoggedInComponent":
                    XCTAssertEqual(serializedProperties, "")
                default:
                    XCTFail("Unverified provider path: \(provider.data.unprocessed.pathString)")
                }
            }
        }
    }
}
