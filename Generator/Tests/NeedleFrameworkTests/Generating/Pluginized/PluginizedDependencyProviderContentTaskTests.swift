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
        let (components, pluginizedComponents, _) = pluginizedSampleProjectParsed()


        var allProviders = [DependencyProvider]()
        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            allProviders.append(contentsOf: task.execute())
        }
        for component in pluginizedComponents {
            let task = DependencyProviderDeclarerTask(component: component.data)
            allProviders.append(contentsOf: task.execute())
        }

        let task = PluginizedDependencyProviderContentTask(providers: allProviders, pluginizedComponents: pluginizedComponents)
        let allProcessedProviders = task.execute()

        XCTAssertEqual(allProcessedProviders.count, 8)
        verify(allProcessedProviders)
    }

    private func verify(_ providers: [PluginizedProcessedDependencyProvider]) {
        XCTAssertEqual(providers[0].data.levelMap["RootComponent"], 1)
        XCTAssertEqual(providers[0].processedProperties[0].data.unprocessed.name, "mutablePlayersStream")
        XCTAssertEqual(providers[0].processedProperties[0].data.sourceComponentType, "RootComponent")
        XCTAssertEqual(providers[0].processedProperties[0].auxillarySourceType, nil)

        XCTAssertEqual(providers[2].data.levelMap["LoggedInComponent"], 3)
        XCTAssertEqual(providers[2].processedProperties[0].data.unprocessed.name, "scoreStream")
        XCTAssertEqual(providers[2].processedProperties[0].auxillarySourceName, "LoggedInNonCoreComponent")
        XCTAssertEqual(providers[2].processedProperties[0].data.sourceComponentType, "LoggedInComponent")
        XCTAssertEqual(providers[2].processedProperties[0].auxillarySourceType, .nonCoreComponent)

        XCTAssertEqual(providers[3].data.levelMap["LoggedInNonCoreComponent"], 1)
        XCTAssertEqual(providers[3].processedProperties[0].data.unprocessed.name, "scoreStream")
        XCTAssertEqual(providers[3].processedProperties[0].data.sourceComponentType, "LoggedInNonCoreComponent")
        XCTAssertEqual(providers[3].processedProperties[0].auxillarySourceType, nil)

        XCTAssertEqual(providers[6].data.levelMap["LoggedInComponent"], 1)
        XCTAssertEqual(providers[6].data.levelMap["RootComponent"], 2)
        XCTAssertEqual(providers[6].processedProperties[0].data.unprocessed.name, "mutableScoreStream")
        XCTAssertEqual(providers[6].processedProperties[0].auxillarySourceName, "LoggedInPluginExtension")
        XCTAssertEqual(providers[6].processedProperties[0].data.sourceComponentType, "LoggedInComponent")
        XCTAssertEqual(providers[6].processedProperties[0].auxillarySourceType, .pluginExtension)
        XCTAssertEqual(providers[6].processedProperties[1].data.unprocessed.name, "playersStream")
        XCTAssertEqual(providers[6].processedProperties[1].data.sourceComponentType, "RootComponent")
        XCTAssertEqual(providers[6].processedProperties[1].auxillarySourceType, nil)
    }
}
