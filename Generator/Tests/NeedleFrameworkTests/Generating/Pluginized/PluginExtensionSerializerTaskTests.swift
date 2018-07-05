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

class PluginExtensionSerializerTaskTests: AbstractPluginizedGeneratorTests {

    static var allTests = [
        ("test_execute_withSampleProject_verifySerialization", test_execute_withSampleProject_verifySerialization),
        ]

    func test_execute_withSampleProject_verifySerialization() {
        var flattenRegistrations = ""
        var flattenContents = ""

        let (_, pluginizedComponents, _) = pluginizedSampleProjectParsed()

        for pluginizedComponent in pluginizedComponents {
            let provider = PluginExtensionSerializerTask(component: pluginizedComponent).execute()
            flattenRegistrations += provider.registration + "\n"
            flattenContents += provider.content + "\n"
        }

        let expectedRegistrations =
        """
        __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "GameComponent") { component in
            return GamePluginExtensionProvider(component: component)
        }

        __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "LoggedInComponent") { component in
            return LoggedInPluginExtensionProvider(component: component)
        }


        """

        let expectedContents =
        """
        /// GameComponent
        private class GamePluginExtensionProvider: GamePluginExtension {
            var scoreSheetBuilder: ScoreSheetBuilder {
                return gameNonCoreComponent.scoreSheetBuilder
            }
            private unowned let gameNonCoreComponent: GameNonCoreComponent
            init(component: ComponentType) {
                let gameComponent = component as! GameComponent
                gameNonCoreComponent = gameComponent.nonCoreComponent as! GameNonCoreComponent
            }
        }

        /// LoggedInComponent
        private class LoggedInPluginExtensionProvider: LoggedInPluginExtension {
            var scoreSheetBuilder: ScoreSheetBuilder {
                return loggedInNonCoreComponent.scoreSheetBuilder
            }
            var mutableScoreStream: MutableScoreStream {
                return loggedInNonCoreComponent.mutableScoreStream
            }
            private unowned let loggedInNonCoreComponent: LoggedInNonCoreComponent
            init(component: ComponentType) {
                let loggedInComponent = component as! LoggedInComponent
                loggedInNonCoreComponent = loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent
            }
        }


        """

        XCTAssertEqual(flattenRegistrations, expectedRegistrations)
        XCTAssertEqual(flattenContents, expectedContents)
    }
}
