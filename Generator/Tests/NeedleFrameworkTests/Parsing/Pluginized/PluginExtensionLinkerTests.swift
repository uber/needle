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

class PluginExtensionLinkerTests: AbstractParserTests {

    func test_process_withComponents_verifyLinkages() {
        let data = ASTComponent(name: "SomePluginizedComp", dependencyProtocolName: "Doesn't matter", isRoot: false, sourceHash: "SomePluginizedCompHash", properties: [], expressionCallTypeNames: [])
        let pluginizedComp = PluginizedASTComponent(data: data, pluginExtensionType: "MyExtension", nonCoreComponentType: "Doesn't matter")
        let pluginExtension = PluginExtension(name: "MyExtension", properties: [])

        let linker = PluginExtensionLinker(pluginizedComponents: [pluginizedComp], pluginExtensions: [pluginExtension])

        try! linker.process()

        XCTAssertTrue(pluginizedComp.pluginExtension == pluginExtension)
    }

    func test_process_withComponentsNoPluginExtension_verifyError() {
        let data = ASTComponent(name: "SomePluginizedComp", dependencyProtocolName: "Doesn't matter", isRoot: false, sourceHash: "SomePluginizedCompHash", properties: [], expressionCallTypeNames: [])
        let pluginizedComp = PluginizedASTComponent(data: data, pluginExtensionType: "StuffExtension", nonCoreComponentType: "SomeComp")

        let linker = PluginExtensionLinker(pluginizedComponents: [pluginizedComp], pluginExtensions: [])

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
