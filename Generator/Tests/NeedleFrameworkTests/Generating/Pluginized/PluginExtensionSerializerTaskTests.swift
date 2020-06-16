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

    func test_execute_withSampleProject_verifySerialization() {
        let (_, pluginizedComponents, _, _) = pluginizedSampleProjectParsed()

        for pluginizedComponent in pluginizedComponents {
            let provider = PluginExtensionSerializerTask(component: pluginizedComponent).execute()

            switch pluginizedComponent.data.name {
            case "GameComponent":
                XCTAssertEqual(provider.registration, "__PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: \"GameComponent\") { component in\n    return GamePluginExtensionProvider(component: component)\n}\n")
                XCTAssertEqual(provider.content, "/// GameComponent plugin extension\nprivate class GamePluginExtensionProvider: GamePluginExtension {\n    var scoreSheetBuilder: ScoreSheetBuilder {\n        return gameNonCoreComponent.scoreSheetBuilder\n    }\n    private unowned let gameNonCoreComponent: GameNonCoreComponent\n    init(component: NeedleFoundation.Scope) {\n        let gameComponent = component as! GameComponent\n        gameNonCoreComponent = gameComponent.nonCoreComponent as! GameNonCoreComponent\n    }\n}\n")
            case "LoggedInComponent":
                XCTAssertEqual(provider.registration, "__PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: \"LoggedInComponent\") { component in\n    return LoggedInPluginExtensionProvider(component: component)\n}\n")
                XCTAssertEqual(provider.content, "/// LoggedInComponent plugin extension\nprivate class LoggedInPluginExtensionProvider: LoggedInPluginExtension {\n    var scoreSheetBuilder: ScoreSheetBuilder {\n        return loggedInNonCoreComponent.scoreSheetBuilder\n    }\n    var mutableScoreStream: MutableScoreStream {\n        return loggedInNonCoreComponent.mutableScoreStream\n    }\n    private unowned let loggedInNonCoreComponent: LoggedInNonCoreComponent\n    init(component: NeedleFoundation.Scope) {\n        let loggedInComponent = component as! LoggedInComponent\n        loggedInNonCoreComponent = loggedInComponent.nonCoreComponent as! LoggedInNonCoreComponent\n    }\n}\n")
            default:
                XCTFail("Unverified provider for component: \(pluginizedComponent.data.name)")
            }
        }
    }
}
