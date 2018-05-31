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

    static var allTests = [
        ("test_execute_withSampleProject_verifyProviderDeclarations", test_execute_withSampleProject_verifyProviderDeclarations),
    ]

    func test_execute_withSampleProject_verifyProviderDeclarations() {
        let components = sampleProjectComponents()
        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            let result = task.execute()
            switch result {
            case .endOfSequence(_):
                XCTFail()
            case .continueSequence(let task):
                let providers = (task as! DependencyProviderContentTask).providers
                switch component.name {
                case "GameComponent":
                    XCTAssertEqual(providers.count, 1)
                    XCTAssertEqual(providers[0].name, "GameDependency_2401566548657102800Provider")
                    XCTAssertEqual(providers[0].pathString, "^->RootComponent->LoggedInComponent->GameComponent")
                    XCTAssertEqual(providers[0].dependency, component.dependency)
                    XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                    XCTAssertEqual(providers[0].path[1].name, "LoggedInComponent")
                    XCTAssertEqual(providers[0].path[2].name, "GameComponent")
                case "ScoreSheetComponent":
                    XCTAssertEqual(providers.count, 2)
                    for provider in providers {
                        switch provider.name {
                        case "ScoreSheetDependency_1515114331612493672Provider":
                            XCTAssertEqual(provider.pathString, "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent")
                            XCTAssertEqual(provider.dependency, component.dependency)
                            XCTAssertEqual(provider.path[0].name, "RootComponent")
                            XCTAssertEqual(provider.path[1].name, "LoggedInComponent")
                            XCTAssertEqual(provider.path[2].name, "GameComponent")
                            XCTAssertEqual(provider.path[3].name, "ScoreSheetComponent")
                        case "ScoreSheetDependency8667150673442932147Provider":
                            XCTAssertEqual(provider.pathString, "^->RootComponent->LoggedInComponent->ScoreSheetComponent")
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
                    XCTAssertEqual(providers[0].name, "LoggedOutDependency5490810220359560589Provider")
                    XCTAssertEqual(providers[0].pathString, "^->RootComponent->LoggedOutComponent")
                    XCTAssertEqual(providers[0].dependency, component.dependency)
                    XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                    XCTAssertEqual(providers[0].path[1].name, "LoggedOutComponent")
                case "LoggedInComponent":
                    XCTAssertEqual(providers.count, 1)
                    XCTAssertEqual(providers[0].name, "EmptyDependency4815886340652882587Provider")
                    XCTAssertEqual(providers[0].pathString, "^->RootComponent->LoggedInComponent")
                    XCTAssertEqual(providers[0].dependency, component.dependency)
                    XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                    XCTAssertEqual(providers[0].path[1].name, "LoggedInComponent")
                case "RootComponent":
                    XCTAssertEqual(providers.count, 1)
                    XCTAssertEqual(providers[0].name, "EmptyDependency_351536060279651311Provider")
                    XCTAssertEqual(providers[0].pathString, "^->RootComponent")
                    XCTAssertEqual(providers[0].dependency, component.dependency)
                    XCTAssertEqual(providers[0].path[0].name, "RootComponent")
                default:
                    XCTFail()
                }
            }
        }
    }
}
