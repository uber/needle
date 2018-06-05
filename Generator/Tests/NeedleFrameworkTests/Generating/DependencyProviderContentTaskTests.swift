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

    static var allTests = [
        ("test_execute_withSampleProject_verifyProviderContent", test_execute_withSampleProject_verifyProviderContent),
    ]

    func test_execute_withSampleProject_verifyProviderContent() {
        let (components, imports) = sampleProjectParsed()
        var i = 0
        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            let result = task.execute()
            switch result {
            case .continueSequence(let contentTask):
                let contentResult = contentTask.execute()
                switch contentResult {
                case .continueSequence(let serializerTask):
                    // Verify
                    verify((serializerTask as! DependencyProviderSerializerTask).providers, count: i)
                case .endOfSequence(_):
                    XCTFail()
                }
            case .endOfSequence(_):
                XCTFail()
            }
            i += 1
        }

        XCTAssertEqual(imports, ["import NeedleFoundation", "import RxSwift", "import UIKit"])
    }

    private func verify(_ providers: [ProcessedDependencyProvider], count: Int) {
        switch count {
        case 0:
            XCTAssertEqual(providers[0].levelMap["LoggedInComponent"], 1)
            XCTAssertEqual(providers[0].levelMap["RootComponent"], 2)
            XCTAssertEqual(providers[0].processedProperties[0].unprocessed.name, "mutableScoreStream")
            XCTAssertEqual(providers[0].processedProperties[0].sourceComponentType, "LoggedInComponent")
            XCTAssertEqual(providers[0].processedProperties[1].unprocessed.name, "playersStream")
            XCTAssertEqual(providers[0].processedProperties[1].sourceComponentType, "RootComponent")
        case 1:
            XCTAssertEqual(providers[0].levelMap["LoggedInComponent"], 2)
            XCTAssertEqual(providers[0].processedProperties[0].unprocessed.name, "scoreStream")
            XCTAssertEqual(providers[0].processedProperties[0].sourceComponentType, "LoggedInComponent")
            XCTAssertEqual(providers[1].levelMap["LoggedInComponent"], 1)
            XCTAssertEqual(providers[1].processedProperties[0].unprocessed.name, "scoreStream")
            XCTAssertEqual(providers[1].processedProperties[0].sourceComponentType, "LoggedInComponent")
        case 2:
            XCTAssertEqual(providers[0].levelMap["RootComponent"], 1)
            XCTAssertEqual(providers[0].processedProperties[0].unprocessed.name, "mutablePlayersStream")
            XCTAssertEqual(providers[0].processedProperties[0].sourceComponentType, "RootComponent")
        default:
            break
        }
    }
}
