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

import XCTest
@testable import NeedleFramework

class DependencyProviderDeclarerTaskTests: AbstractGeneratorTests {

    func test_execute_withSampleProject_verifyProviderDeclarations() {
        let (components, imports) = sampleProjectParsed()
        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            let providers = task.execute()

            switch component.name {
            case "GameComponent":
                XCTAssertEqual(providers.count, 1)
                XCTAssertEqual(providers[0].pathString, "^->RootComponent->LoggedInComponent->GameComponent")
                XCTAssertEqual(providers[0].dependency, component.dependency)
                XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                XCTAssertEqual(providers[0].path[1].name, "LoggedInComponent")
                XCTAssertEqual(providers[0].path[2].name, "GameComponent")
            case "ScoreSheetComponent":
                XCTAssertEqual(providers.count, 2)
                for provider in providers {
                    switch provider.pathString {
                    case "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent":
                        XCTAssertEqual(provider.dependency, component.dependency)
                        XCTAssertEqual(provider.path[0].name, "RootComponent")
                        XCTAssertEqual(provider.path[1].name, "LoggedInComponent")
                        XCTAssertEqual(provider.path[2].name, "GameComponent")
                        XCTAssertEqual(provider.path[3].name, "ScoreSheetComponent")
                    case "^->RootComponent->LoggedInComponent->ScoreSheetComponent":
                        XCTAssertEqual(provider.dependency, component.dependency)
                        XCTAssertEqual(provider.path[0].name, "RootComponent")
                        XCTAssertEqual(provider.path[1].name, "LoggedInComponent")
                        XCTAssertEqual(provider.path[2].name, "ScoreSheetComponent")
                    default:
                        XCTFail()
                    }
                }
            case "LoggedOutComponent":
                XCTAssertEqual(providers.count, 1)
                XCTAssertEqual(providers[0].pathString, "^->RootComponent->LoggedOutComponent")
                XCTAssertEqual(providers[0].dependency, component.dependency)
                XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                XCTAssertEqual(providers[0].path[1].name, "LoggedOutComponent")
            case "LoggedInComponent":
                XCTAssertEqual(providers.count, 1)
                XCTAssertEqual(providers[0].pathString, "^->RootComponent->LoggedInComponent")
                XCTAssertEqual(providers[0].dependency, component.dependency)
                XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                XCTAssertEqual(providers[0].path[1].name, "LoggedInComponent")
            case "RootComponent":
                XCTAssertEqual(providers.count, 1)
                XCTAssertEqual(providers[0].pathString, "^->RootComponent")
                XCTAssertEqual(providers[0].dependency, component.dependency)
                XCTAssertEqual(providers[0].path[0].name, "RootComponent")
            default:
                XCTFail()
            }
        }

        XCTAssertEqual(imports, ["import NeedleFoundation", "import RxSwift", "import UIKit"])
    }
}
