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

class ComponentExtensionFilterTests: AbstractParserTests {

    func test_execute_hasComponentExtension_verifyFilter() {
        let fileUrl = fixtureUrl(for: "HasComponentExtensions.swift")
        let content = try! String(contentsOf: fileUrl)
        let filter = ComponentExtensionFilter(content: content, components: [ASTComponent(name: "MyScope", dependencyProtocolName: "", isRoot: false, sourceHash: "MyScopeHash", properties: [], expressionCallTypeNames: [])])

        XCTAssertTrue(filter.filter())
    }

    func test_execute_noExtensionNoComponent_verifyFilter() {
        let fileUrl = fixtureUrl(for: "nocomp.swift")
        let content = try! String(contentsOf: fileUrl)
        let filter = ComponentExtensionFilter(content: content, components: [ASTComponent(name: "MyComponent", dependencyProtocolName: "", isRoot: false, sourceHash: "MyComponentHash", properties: [], expressionCallTypeNames: [])])

        XCTAssertFalse(filter.filter())
    }
}
