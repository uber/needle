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

class NonCoreComponentLinkerTests: AbstractParserTests {

    func test_process_withComponents_verifyLinkages() {
        let data = ASTComponent(name: "SomePluginizedComp", dependencyProtocolName: "Doesn't matter", isRoot: true, sourceHash: "SomePluginizedCompHash", properties: [], expressionCallTypeNames: [])
        let pluginizedComp = PluginizedASTComponent(data: data, pluginExtensionType: "Doesn't matter", nonCoreComponentType: "SomeComp")
        let nonCoreComponent = ASTComponent(name: "SomeComp", dependencyProtocolName: "ItsDependency", isRoot: false, sourceHash: "SomeCompHash", properties: [], expressionCallTypeNames: [])

        let linker = NonCoreComponentLinker(pluginizedComponents: [pluginizedComp], nonCoreComponents: [nonCoreComponent])

        try! linker.process()

        XCTAssertTrue(pluginizedComp.nonCoreComponent === nonCoreComponent)
    }

    func test_process_withComponentsNoNonCoreComp_verifyError() {
        let data = ASTComponent(name: "SomePluginizedComp", dependencyProtocolName: "Doesn't matter", isRoot: false, sourceHash: "SomePluginizedCompHash", properties: [], expressionCallTypeNames: [])
        let pluginizedComp = PluginizedASTComponent(data: data, pluginExtensionType: "Doesn't matter", nonCoreComponentType: "SomeComp")
        let nonCoreComponent = ASTComponent(name: "WrongNonCoreComp", dependencyProtocolName: "ItsDependency", isRoot: true, sourceHash: "WrongNonCoreCompHash", properties: [], expressionCallTypeNames: [])

        let linker = NonCoreComponentLinker(pluginizedComponents: [pluginizedComp], nonCoreComponents: [nonCoreComponent])

        do {
            try linker.process()
            XCTFail()
        } catch GenericError.withMessage(_) {
            // Success.
        } catch {
            XCTFail()
        }
    }
}
