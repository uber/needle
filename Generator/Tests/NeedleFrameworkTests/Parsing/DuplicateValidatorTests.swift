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

import SourceParsingFramework
import XCTest
@testable import NeedleFramework

class DuplicateValidatorTests: XCTestCase {
    
    func test_validateComponent_noDuplicate_verifyResult() {
        let comp1 = ASTComponent(name: "ha1", dependencyProtocolName: "dep1", isRoot: false, sourceHash: "ha1Hash", properties: [], expressionCallTypeNames: [])
        let comp2 = ASTComponent(name: "ha2", dependencyProtocolName: "dep1", isRoot: false, sourceHash: "ha2Hash", properties: [], expressionCallTypeNames: [])
        let comp3 = ASTComponent(name: "ha3", dependencyProtocolName: "dep1", isRoot: false, sourceHash: "ha3Hash", properties: [], expressionCallTypeNames: [])

        let validator = DuplicateValidator(components: [comp1, comp2, comp3], dependencies: [])

        try! validator.process()
    }

    func test_validateComponent_withDuplicates_verifyResult() {
        let comp1 = ASTComponent(name: "ha1", dependencyProtocolName: "dep1", isRoot: false, sourceHash: "ha1Hash", properties: [], expressionCallTypeNames: [])
        let comp2 = ASTComponent(name: "ha1", dependencyProtocolName: "dep1", isRoot: false, sourceHash: "ha1Hash", properties: [], expressionCallTypeNames: [])
        let comp3 = ASTComponent(name: "ha3", dependencyProtocolName: "dep1", isRoot: false, sourceHash: "ha3Hash", properties: [], expressionCallTypeNames: [])

        let validator = DuplicateValidator(components: [comp1, comp2, comp3], dependencies: [])

        do  {
            try validator.process()
        } catch GenericError.withMessage(let message) {
            XCTAssertTrue(message.contains("ha1"))
        } catch {
            XCTFail()
        }
    }

    func test_validateDependencies_noDuplicate_verifyResult() {
        let dep1 = Dependency(name: "d1", properties: [], sourceHash: "d1Hash")
        let dep2 = Dependency(name: "d2", properties: [], sourceHash: "d2Hash")
        let dep3 = Dependency(name: "d3", properties: [], sourceHash: "d3Hash")

        let validator = DuplicateValidator(components: [], dependencies: [dep1, dep2, dep3])

        try! validator.process()
    }

    func test_validateDependencies_withDuplicates_verifyResult() {
        let dep1 = Dependency(name: "d1", properties: [], sourceHash: "d1Hash")
        let dep2 = Dependency(name: "d1", properties: [], sourceHash: "d2Hash")
        let dep3 = Dependency(name: "d3", properties: [], sourceHash: "d3Hash")

        let validator = DuplicateValidator(components: [], dependencies: [dep1, dep2, dep3])

        do  {
            try validator.process()
        } catch GenericError.withMessage(let message) {
            XCTAssertTrue(message.contains("d1"))
        } catch {
            XCTFail()
        }
    }
}
