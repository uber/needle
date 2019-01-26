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

import SourceKittenFramework
import XCTest
@testable import NeedleFramework

class ComponentInstantiationValidatorTests: AbstractParserTests {

    func test_withValidInstantiations_verifyNoError() {
        let content = self.content(of: "ValidInits.swift")
        let components = [astComponent(withName: "MyComponent"), astComponent(withName: "My1Component"), astComponent(withName: "MyComponent2"), astComponent(withName: "MyCompo3nent"), astComponent(withName: "RootComponent")]
        let validator = ComponentInstantiationValidator(components: components, fileContents: [content])
        do {
            try validator.process()
        } catch {
            XCTFail()
        }
    }

    func test_withInvalidInstantiations_verifyErrors() {
        var content = self.content(of: "InvalidInits/InvalidInits1.swift")
        let components = [astComponent(withName: "MyComponent"), astComponent(withName: "MyComponent2"), astComponent(withName: "My5Component"), astComponent(withName: "MyComp6onent6"), astComponent(withName: "RootComponent")]
        var validator = ComponentInstantiationValidator(components: components, fileContents: [content])
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "MyComponent")
        }

        content = self.content(of: "InvalidInits/InvalidInits2.swift")
        validator = ComponentInstantiationValidator(components: components, fileContents: [content])
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "MyComponent2")
        }

        content = self.content(of: "InvalidInits/InvalidInits3.swift")
        validator = ComponentInstantiationValidator(components: components, fileContents: [content])
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "My5Component")
        }

        content = self.content(of: "InvalidInits/InvalidInits4.swift")
        validator = ComponentInstantiationValidator(components: components, fileContents: [content])
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "MyComp6onent6")
        }
    }

    func test_withInvalidInstantiations_notAComponent_verifyNoError() {
        let content = self.content(of: "InvalidInits/InvalidInits1.swift")
        let components = [astComponent(withName: "ADifferentComponent")]
        let validator = ComponentInstantiationValidator(components: components, fileContents: [content])
        do {
            try validator.process()
        } catch {
            XCTFail()
        }
    }

    private func content(of fileName: String) -> String {
        let fileUrl = fixtureUrl(for: fileName)
        return try! String(contentsOf: fileUrl)
    }

    private func astComponent(withName name: String) -> ASTComponent{
        return ASTComponent(name: name, dependencyProtocolName: "", properties: [], expressionCallTypeNames: [])
    }

    private func validate(error: Error, withComponentName componentName: String) {
        XCTAssert(error is GeneratorError)
        switch error {
        case GeneratorError.withMessage(let message):
            XCTAssertTrue(message.contains(componentName))
        default:
            XCTFail()
        }
    }
}
