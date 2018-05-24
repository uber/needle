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
        var flattenRegistrations = ""
        var flattenContents = ""

        let components = sampleProjectComponents()
        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            let result = task.execute()
            switch result {
            case .continueSequence(let contentTask):
                let contentResult = contentTask.execute()
                switch contentResult {
                case .continueSequence(let serializerTask):
                    let serializationResult = serializerTask.execute()
                    switch serializationResult {
                    case .continueSequence(_):
                        XCTFail()
                    case .endOfSequence(let serialized):
                        for item in serialized {
                            flattenRegistrations += item.registration
                            flattenContents += item.content
                        }
                    }
                case .endOfSequence(_):
                    XCTFail()
                }
            case .endOfSequence(_):
                XCTFail()
            }
        }

        let expectedRegistration = """
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
            return GameDependency_2401566548657102800Provider(component: component)
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent") { component in
            return ScoreSheetDependency_1515114331612493672Provider(component: component)
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->ScoreSheetComponent") { component in
            return ScoreSheetDependency8667150673442932147Provider(component: component)
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedOutComponent") { component in
            return LoggedOutDependency5490810220359560589Provider(component: component)
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent") { component in
            return EmptyDependencyProvider(component: component)
        }
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent") { component in
            return EmptyDependencyProvider(component: component)
        }\n
        """
        XCTAssertEqual(flattenRegistrations, expectedRegistration)

        let expectedContents = """
        /// ^->RootComponent->LoggedInComponent->GameComponent
        private class GameDependency_2401566548657102800Provider: GameDependency {
            var mutableScoreStream: MutableScoreStream {
                return loggedInComponent.mutableScoreStream
            }
            var playersStream: PlayersStream {
                return rootComponent.playersStream
            }
            private let loggedInComponent: LoggedInComponent
            private let rootComponent: RootComponent
            init(component: ComponentType) {
                loggedInComponent = component.parent as! LoggedInComponent
                rootComponent = component.parent.parent as! RootComponent
            }
        }
        /// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent
        private class ScoreSheetDependency_1515114331612493672Provider: ScoreSheetDependency {
            var scoreStream: ScoreStream {
                return loggedInComponent.scoreStream
            }
            private let loggedInComponent: LoggedInComponent
            init(component: ComponentType) {
                loggedInComponent = component.parent.parent as! LoggedInComponent
            }
        }
        /// ^->RootComponent->LoggedInComponent->ScoreSheetComponent
        private class ScoreSheetDependency8667150673442932147Provider: ScoreSheetDependency {
            var scoreStream: ScoreStream {
                return loggedInComponent.scoreStream
            }
            private let loggedInComponent: LoggedInComponent
            init(component: ComponentType) {
                loggedInComponent = component.parent as! LoggedInComponent
            }
        }
        /// ^->RootComponent->LoggedOutComponent
        private class LoggedOutDependency5490810220359560589Provider: LoggedOutDependency {
            var mutablePlayersStream: MutablePlayersStream {
                return rootComponent.mutablePlayersStream
            }
            private let rootComponent: RootComponent
            init(component: ComponentType) {
                rootComponent = component.parent as! RootComponent
            }
        }\n
        """

        XCTAssertEqual(flattenContents, expectedContents)
    }
}
