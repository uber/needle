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

class DuplicateValidatorTests: XCTestCase {
    
    func test_validateComponent_noDuplicate_verifyResult() {
        let comp1 = Component(name: "ha1", dependencyProtocolName: "dep1", properties: [])
        let comp2 = Component(name: "ha2", dependencyProtocolName: "dep1", properties: [])
        let comp3 = Component(name: "ha3", dependencyProtocolName: "dep1", properties: [])

        let validator = DuplicateValidator()

        let result = validator.validate([comp1, comp2, comp3])

        switch result {
        case .duplicate(_):
            XCTFail()
        default:
            break
        }
    }

    func test_validateComponent_withDuplicates_verifyResult() {
        let comp1 = Component(name: "ha1", dependencyProtocolName: "dep1", properties: [])
        let comp2 = Component(name: "ha1", dependencyProtocolName: "dep1", properties: [])
        let comp3 = Component(name: "ha3", dependencyProtocolName: "dep1", properties: [])

        let validator = DuplicateValidator()

        let result = validator.validate([comp1, comp2, comp3])

        switch result {
        case .duplicate(let name):
            XCTAssertEqual(name, "ha1")
        default:
            XCTFail()
        }
    }

    func test_validateDependencies_noDuplicate_verifyResult() {
        let dep1 = Dependency(name: "d1", properties: [])
        let dep2 = Dependency(name: "d2", properties: [])
        let dep3 = Dependency(name: "d3", properties: [])

        let validator = DuplicateValidator()

        let result = validator.validate([dep1, dep2, dep3])

        switch result {
        case .duplicate(_):
            XCTFail()
        default:
            break
        }
    }

    func test_validateDependencies_withDuplicates_verifyResult() {
        let dep1 = Dependency(name: "d1", properties: [])
        let dep2 = Dependency(name: "d1", properties: [])
        let dep3 = Dependency(name: "d3", properties: [])

        let validator = DuplicateValidator()

        let result = validator.validate([dep1, dep2, dep3])

        switch result {
        case .duplicate(let name):
            XCTAssertEqual(name, "d1")
        default:
            XCTFail()
        }
    }
}
