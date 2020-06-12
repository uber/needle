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

import Concurrency
import SourceParsingFramework
import XCTest
@testable import NeedleFramework

class ComponentInstantiationValidatorTests: AbstractParserTests {

    private var executor: SequenceExecutor!

    override func setUp() {
        super.setUp()

        executor = MockSequenceExecutor()
    }

    func test_withValidInstantiations_verifyNoError() {
        let urlContent = self.urlContent(of: "ValidInits.swift")
        let components = [astComponent(withName: "MyComponent"), astComponent(withName: "My1Component"), astComponent(withName: "MyComponent2"), astComponent(withName: "MyCompo3nent"), astComponent(withName: "RootComponent")]
        let validator = ComponentInstantiationValidator(components: components, urlFileContents: [urlContent], executor: executor, timeout: 3)
        do {
            try validator.process()
        } catch {
            XCTFail()
        }
    }

    func test_withInvalidInstantiations_verifyErrors() {
        var urlContent = self.urlContent(of: "InvalidInits/InvalidInits1.swift")
        let components = [astComponent(withName: "MyComponent"), astComponent(withName: "MyComponent2"), astComponent(withName: "My5Component"), astComponent(withName: "MyComp6onent6"), astComponent(withName: "RootComponent")]
        var validator = ComponentInstantiationValidator(components: components, urlFileContents: [urlContent], executor: executor, timeout: 3)
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "MyComponent")
        }

        urlContent = self.urlContent(of: "InvalidInits/InvalidInits2.swift")
        validator = ComponentInstantiationValidator(components: components, urlFileContents: [urlContent], executor: executor, timeout: 3)
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "MyComponent2")
        }

        urlContent = self.urlContent(of: "InvalidInits/InvalidInits3.swift")
        validator = ComponentInstantiationValidator(components: components, urlFileContents: [urlContent], executor: executor, timeout: 3)
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "My5Component")
        }

        urlContent = self.urlContent(of: "InvalidInits/InvalidInits4.swift")
        validator = ComponentInstantiationValidator(components: components, urlFileContents: [urlContent], executor: executor, timeout: 3)
        do {
            try validator.process()
            XCTFail()
        } catch {
            validate(error: error, withComponentName: "MyComp6onent6")
        }
    }

    func test_withInvalidInstantiations_notAComponent_verifyNoError() {
        let urlContent = self.urlContent(of: "InvalidInits/InvalidInits1.swift")
        let components = [astComponent(withName: "ADifferentComponent")]
        let validator = ComponentInstantiationValidator(components: components, urlFileContents: [urlContent], executor: executor, timeout: 3)
        do {
            try validator.process()
        } catch {
            XCTFail()
        }
    }

    private func urlContent(of fileName: String) -> UrlFileContent {
        let fileUrl = fixtureUrl(for: fileName)
        return try! (fileUrl, String(contentsOf: fileUrl))
    }

    private func astComponent(withName name: String) -> ASTComponent{
        return ASTComponent(name: name, dependencyProtocolName: "", isRoot: false, sourceHash: name + "Hash", properties: [], expressionCallTypeNames: [])
    }

    private func validate(error: Error, withComponentName componentName: String) {
        XCTAssert(error is GenericError)
        switch error {
        case GenericError.withMessage(let message):
            XCTAssertTrue(message.contains(componentName))
        default:
            XCTFail()
        }
    }
}
