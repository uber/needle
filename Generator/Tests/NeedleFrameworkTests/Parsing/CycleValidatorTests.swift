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

class CycleValidatorTests: XCTestCase {

    func test_process_hasCycle() {
        let a = ASTComponent(name: "A", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let b = ASTComponent(name: "B", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let c = ASTComponent(name: "C", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let d = ASTComponent(name: "D", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let m = ASTComponent(name: "M", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        a.parents = [b, m]
        b.parents = [c, d]
        c.parents = [b]

        let processor = CycleValidator(components: [a, b, c, d, m])
        do {
            try processor.process()
            XCTFail()
        } catch {
        }
    }

    func test_process_noCycle() {
        let a = ASTComponent(name: "A", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let b = ASTComponent(name: "B", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let c = ASTComponent(name: "C", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let d = ASTComponent(name: "D", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        let m = ASTComponent(name: "M", dependencyProtocolName: "blah", properties: [], expressionCallTypeNames: [])
        a.parents = [b, m]
        b.parents = [c, d]
        c.parents = [m]

        let processor = CycleValidator(components: [a, b, c, d, m])
        do {
            try processor.process()
        } catch {
            XCTFail()
        }
    }
}
