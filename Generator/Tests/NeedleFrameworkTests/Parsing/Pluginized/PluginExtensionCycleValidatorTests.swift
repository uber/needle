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

class PluginExtensionCycleValidatorTests: AbstractPluginizedParserTests {

    func test_process_withNoCycles_verifyNoError() {
        let pluginExtension = PluginExtension(name: "PE", properties: [Property(name: "a", type: "A")])

        let nonCoreDependency = Dependency(name: "NonCoreDep", properties: [Property(name: "b", type: "B")], sourceHash: "NonCoreDepHash")
        let nonCoreComponent = ASTComponent(name: "NonCoreComp", dependencyProtocolName: "NonCoreDep", isRoot: false, sourceHash: "NonCoreDepHash", properties: [Property(name: "c", type: "D")], expressionCallTypeNames: [])
        nonCoreComponent.dependencyProtocol = nonCoreDependency

        let coreComponent = ASTComponent(name: "CoreComp", dependencyProtocolName: "blah", isRoot: true, sourceHash: "CoreCompHash", properties: [Property(name: "e", type: "E")], expressionCallTypeNames: [])
        let pluginizedComponent = PluginizedASTComponent(data: coreComponent, pluginExtensionType: "PE", nonCoreComponentType: "NonCoreComp")
        pluginizedComponent.pluginExtension = pluginExtension
        pluginizedComponent.nonCoreComponent = nonCoreComponent

        let validator = PluginExtensionCycleValidator(pluginizedComponents: [pluginizedComponent])

        do {
            try validator.process()
        } catch {
            XCTFail()
        }
    }

    func test_process_withCycles_verifyThrowError() {
        let pluginExtension = PluginExtension(name: "PE", properties: [Property(name: "a", type: "A")])

        let nonCoreDependency = Dependency(name: "NonCoreDep", properties: [Property(name: "a", type: "A")], sourceHash: "NonCoreDepHash")
        let nonCoreComponent = ASTComponent(name: "NonCoreComp", dependencyProtocolName: "NonCoreDep", isRoot: false, sourceHash: "NonCoreDepHash", properties: [Property(name: "c", type: "D")], expressionCallTypeNames: [])
        nonCoreComponent.dependencyProtocol = nonCoreDependency

        let coreComponent = ASTComponent(name: "CoreComp", dependencyProtocolName: "blah", isRoot: true, sourceHash: "CoreCompHash", properties: [Property(name: "a", type: "A")], expressionCallTypeNames: [])
        let pluginizedComponent = PluginizedASTComponent(data: coreComponent, pluginExtensionType: "PE", nonCoreComponentType: "NonCoreComp")
        pluginizedComponent.pluginExtension = pluginExtension
        pluginizedComponent.nonCoreComponent = nonCoreComponent

        let validator = PluginExtensionCycleValidator(pluginizedComponents: [pluginizedComponent])

        do {
            try validator.process()
            XCTFail()
        } catch GenericError.withMessage(let message) {
            XCTAssertTrue(message.contains("(a: A)"))
        } catch {
            XCTFail()
        }
    }
}
