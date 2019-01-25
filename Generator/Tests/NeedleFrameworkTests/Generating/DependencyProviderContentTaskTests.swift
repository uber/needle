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

class DependencyProviderContentTaskTests: AbstractGeneratorTests {

    func test_execute_withSampleProject_verifyProviderContent() {
        let (components, imports) = sampleProjectParsed()
        for component in components {
            let providers = DependencyProviderDeclarerTask(component: component).execute()
            let task = DependencyProviderContentTask(providers: providers)
            let processedProviders = try! task.execute()
            switch component.name {
            case "GameComponent":
                verifyGameComponent(processedProviders)
            case "ScoreSheetComponent":
                verifyScoreSheetComponent(processedProviders)
            case "LoggedOutComponent":
                verifyLoggedOutComponent(processedProviders)
            case "LoggedInComponent":
                verifyLoggedInComponent(processedProviders)
            case "RootComponent":
                verifyRootComponent(processedProviders)
            default:
                XCTFail("Unverified component with name: \(component.name)")
            }
        }

        XCTAssertEqual(imports, ["import NeedleFoundation", "import RxSwift", "import UIKit"])
    }

    private func verifyGameComponent(_ providers: [ProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertEqual(providers[0].levelMap.count, 2)
        XCTAssertEqual(providers[0].levelMap["LoggedInComponent"], 1)
        XCTAssertEqual(providers[0].levelMap["RootComponent"], 2)
        XCTAssertEqual(providers[0].processedProperties.count, 2)
        XCTAssertEqual(providers[0].processedProperties[0].unprocessed.name, "mutableScoreStream")
        XCTAssertEqual(providers[0].processedProperties[0].sourceComponentType, "LoggedInComponent")
        XCTAssertEqual(providers[0].processedProperties[1].unprocessed.name, "playersStream")
        XCTAssertEqual(providers[0].processedProperties[1].sourceComponentType, "RootComponent")
    }

    private func verifyScoreSheetComponent(_ providers: [ProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 2)
        XCTAssertEqual(providers[0].levelMap.count, 1)
        XCTAssertEqual(providers[0].levelMap["LoggedInComponent"], 2)
        XCTAssertEqual(providers[0].processedProperties.count, 1)
        XCTAssertEqual(providers[0].processedProperties[0].unprocessed.name, "scoreStream")
        XCTAssertEqual(providers[0].processedProperties[0].sourceComponentType, "LoggedInComponent")
        XCTAssertEqual(providers[1].levelMap.count, 1)
        XCTAssertEqual(providers[1].levelMap["LoggedInComponent"], 1)
        XCTAssertEqual(providers[1].processedProperties.count, 1)
        XCTAssertEqual(providers[1].processedProperties[0].unprocessed.name, "scoreStream")
        XCTAssertEqual(providers[1].processedProperties[0].sourceComponentType, "LoggedInComponent")
    }

    private func verifyLoggedOutComponent(_ providers: [ProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertEqual(providers[0].levelMap.count, 1)
        XCTAssertEqual(providers[0].levelMap["RootComponent"], 1)
        XCTAssertEqual(providers[0].processedProperties.count, 1)
        XCTAssertEqual(providers[0].processedProperties[0].unprocessed.name, "mutablePlayersStream")
        XCTAssertEqual(providers[0].processedProperties[0].sourceComponentType, "RootComponent")
    }

    private func verifyLoggedInComponent(_ providers: [ProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].levelMap.isEmpty)
        XCTAssertTrue(providers[0].processedProperties.isEmpty)
    }

    private func verifyRootComponent(_ providers: [ProcessedDependencyProvider]) {
        XCTAssertEqual(providers.count, 1)
        XCTAssertTrue(providers[0].levelMap.isEmpty)
        XCTAssertTrue(providers[0].processedProperties.isEmpty)
    }
}
