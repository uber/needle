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

class ComponentConsolidatorTests: AbstractParserTests {

    func test_process_withMatchingSets_verifyResults() {
        let components = [ASTComponent(name: "A", dependencyProtocolName: "", isRoot: false, sourceHash: "AHash", properties: [Property(name: "p1", type: "P1")], expressionCallTypeNames: ["E1"])]
        let componentExtensions = [ASTComponentExtension(name: "A", properties: [Property(name: "p2", type: "P2")], expressionCallTypeNames: ["E2"])]

        let processor = ComponentConsolidator(components: components, componentExtensions: componentExtensions)

        try! processor.process()

        XCTAssertEqual(components[0].properties, [Property(name: "p1", type: "P1"), Property(name: "p2", type: "P2")])
        XCTAssertEqual(components[0].expressionCallTypeNames, ["E1", "E2"])
    }

    func test_process_withNonMatchingSets_verifyError() {
        let componentExtensions = [ASTComponentExtension(name: "A", properties: [Property(name: "p2", type: "P2")], expressionCallTypeNames: ["E2"])]

        let processor = ComponentConsolidator(components: [], componentExtensions: componentExtensions)

        do {
            try processor.process()

            XCTFail()
        } catch {
            XCTAssertTrue(error is GenericError)
            XCTAssertTrue("\(error)".contains(componentExtensions[0].name))
        }
    }
}
