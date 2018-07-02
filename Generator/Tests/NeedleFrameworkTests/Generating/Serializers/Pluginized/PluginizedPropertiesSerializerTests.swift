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

    static var allTests = [
        ("test_execute_withSampleProject_verifySerialization", test_execute_withSampleProject_verifySerialization),
    ]

    func test_execute_withSampleProject_verifySerialization() {
        var flattenContents = ""

        let (components, pluginizedComponents, _) = pluginizedSampleProjectParsed()
        for component in components {
            let providers = DependencyProviderDeclarerTask(component: component).execute()
            let processedProviders = PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents).execute()
            for provider in processedProviders {
                let serializedProperties = PluginizedPropertiesSerializer(provider: provider).serialize()
                flattenContents += serializedProperties + "\n"
            }
        }

        for pluginizedComponent in pluginizedComponents {
            let providers = DependencyProviderDeclarerTask(component: pluginizedComponent.data).execute()
            let processedProviders = PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents).execute()
            for provider in processedProviders {
                let serializedProperties = PluginizedPropertiesSerializer(provider: provider).serialize()
                flattenContents += serializedProperties + "\n"
            }
        }

        let expected =
        """
        var mutablePlayersStream: MutablePlayersStream {
            return rootComponent.mutablePlayersStream
        }

        var scoreStream: ScoreStream {
            return (loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent).scoreStream
        }
        var scoreStream: ScoreStream {
            return loggedInNonCoreComponent.scoreStream
        }
        var mutableScoreStream: MutableScoreStream {
            return loggedInComponent.pluginExtension.mutableScoreStream
        }
        var playersStream: PlayersStream {
            return rootComponent.playersStream
        }


        """

        XCTAssertEqual(flattenContents, expected)
    }
}
