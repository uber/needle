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

class PluginizedDependencyProviderContentTaskTests: AbstractPluginizedGeneratorTests {

    func test_execute_withSampleProject_verifyProviderContent() {
        let (components, pluginizedComponents, _, _) = pluginizedSampleProjectParsed()

        for component in components {
            let declareTask = DependencyProviderDeclarerTask(component: component)
            let providers = declareTask.execute()
            let contentTask = PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents)
            let processedProviders = try! contentTask.execute()

            switch component.name {
            case "LoggedOutComponent":
                verifyLoggedOutComponent(processedProviders)
            case "RootComponent":
                verifyRootComponent(processedProviders)
            case "ScoreSheetComponent":
                verifyScoreSheetComponent(processedProviders)
            case "GameNonCoreComponent":
                verifyGameNonCoreComponent(processedProviders)
            case "LoggedInNonCoreComponent":
                verifyLoggedInNonCoreComponent(processedProviders)
            default:
                XCTFail("Unverified component with name: \(component.name)")
            }
        }

        for component in pluginizedComponents {
            let declareTask = DependencyProviderDeclarerTask(component: component.data)
            let providers = declareTask.execute()
            let contentTask = PluginizedDependencyProviderContentTask(providers: providers, pluginizedComponents: pluginizedComponents)
            let processedProviders = try! contentTask.execute()

            switch component.data.name {
            case "GameComponent":
                verifyGameComponent(processedProviders)
            case "LoggedInComponent":
                verifyLoggedInComponent(processedProviders)
            default:
                XCTFail("Unverified component with name: \(component.data.name)")
            }
        }
    }

    private func verifyLoggedOutComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertEqual(providers[0].data.levelMap.count, 1)
        XCTAssertEqual(providers[0].data.levelMap["RootComponent"], 1)
        XCTAssertEqual(providers[0].processedProperties.count, 1)
        XCTAssertEqual(providers[0].processedProperties[0].data.unprocessed.name, "mutablePlayersStream")
        XCTAssertEqual(providers[0].processedProperties[0].data.sourceComponentType, "RootComponent")
        XCTAssertEqual(providers[0].processedProperties[0].auxillarySourceType, nil)
    }

    private func verifyRootComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].data.levelMap.isEmpty)
        XCTAssertTrue(providers[0].processedProperties.isEmpty)
    }

    private func verifyScoreSheetComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 2)
        XCTAssertEqual(providers[0].data.levelMap.count, 1)
        XCTAssertEqual(providers[0].data.levelMap["LoggedInComponent"], 3)
        XCTAssertEqual(providers[0].processedProperties.count, 1)
        XCTAssertEqual(providers[0].processedProperties[0].data.unprocessed.name, "scoreStream")
        XCTAssertEqual(providers[0].processedProperties[0].auxillarySourceName, "LoggedInNonCoreComponent")
        XCTAssertEqual(providers[0].processedProperties[0].data.sourceComponentType, "LoggedInComponent")
        XCTAssertEqual(providers[0].processedProperties[0].auxillarySourceType, .nonCoreComponent)
        XCTAssertEqual(providers[0].data.levelMap.count, 1)
        XCTAssertEqual(providers[1].data.levelMap["LoggedInNonCoreComponent"], 1)
        XCTAssertEqual(providers[0].processedProperties.count, 1)
        XCTAssertEqual(providers[1].processedProperties[0].data.unprocessed.name, "scoreStream")
        XCTAssertEqual(providers[1].processedProperties[0].data.sourceComponentType, "LoggedInNonCoreComponent")
        XCTAssertEqual(providers[1].processedProperties[0].auxillarySourceType, nil)
    }

    private func verifyGameNonCoreComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].data.levelMap.isEmpty)
        XCTAssertTrue(providers[0].processedProperties.isEmpty)
    }

    private func verifyLoggedInNonCoreComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].data.levelMap.isEmpty)
        XCTAssertTrue(providers[0].processedProperties.isEmpty)
    }

    private func verifyGameComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertEqual(providers[0].data.levelMap.count, 2)
        XCTAssertEqual(providers[0].data.levelMap["LoggedInComponent"], 1)
        XCTAssertEqual(providers[0].data.levelMap["RootComponent"], 2)
        XCTAssertEqual(providers[0].processedProperties.count, 2)
        XCTAssertEqual(providers[0].processedProperties[0].data.unprocessed.name, "mutableScoreStream")
        XCTAssertEqual(providers[0].processedProperties[0].data.sourceComponentType, "LoggedInComponent")
        XCTAssertEqual(providers[0].processedProperties[0].auxillarySourceType, .pluginExtension)
        XCTAssertEqual(providers[0].processedProperties[1].data.unprocessed.name, "playersStream")
        XCTAssertEqual(providers[0].processedProperties[1].data.sourceComponentType, "RootComponent")
        XCTAssertEqual(providers[0].processedProperties[1].auxillarySourceType, nil)
    }

    private func verifyLoggedInComponent(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].data.levelMap.isEmpty)
        XCTAssertTrue(providers[0].processedProperties.isEmpty)
    }
}
