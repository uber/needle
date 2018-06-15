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

class FileFilterTaskTests: AbstractParserTests {

    static var allTests = [
        ("test_execute_nonSwiftSource_verifyFilter", test_execute_nonSwiftSource_verifyFilter),
        ("test_execute_excludedSuffix_verifyFilter", test_execute_excludedSuffix_verifyFilter),
        ("test_execute_nonNeedleComponent_verifyFilter", test_execute_nonNeedleComponent_verifyFilter),
        ("test_execute_nonInheritanceComponent_verifyFilter", test_execute_nonInheritanceComponent_verifyFilter),
        ("test_execute_actualComponent_verifyResult", test_execute_actualComponent_verifyResult),
    ]

    func test_execute_nonSwiftSource_verifyFilter() {
        let fileUrl = fixtureUrl(for: "NonSwift.json")
        let task = FileFilterTask(url: fileUrl, exclusionSuffixes: [])

        let result = task.execute()
        switch result {
        case .shouldParse(_, _):
            XCTFail()
        case .skip:
            break
        }
    }

    func test_execute_excludedSuffix_verifyFilter() {
        let fileUrl = fixtureUrl(for: "ComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let excludeSuffixTask = FileFilterTask(url: fileUrl, exclusionSuffixes: ["Sample"])

        var result = excludeSuffixTask.execute()

        switch result {
        case .shouldParse(_, _):
            XCTFail()
        case .skip:
            break
        }

        let includeSuffixTask = FileFilterTask(url: fileUrl, exclusionSuffixes: [])

        result = includeSuffixTask.execute()

        switch result {
        case .shouldParse(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_nonNeedleComponent_verifyFilter() {
        let fixturesURL = fixtureUrl(for: "NonNeedleComponent.swift")
        let task = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        let result = task.execute()

        switch result {
        case .shouldParse(_, _):
            XCTFail()
        case .skip:
            break
        }
    }

    func test_execute_nonInheritanceComponent_verifyFilter() {
        let fixturesURL = fixtureUrl(for: "NonInheritanceComponent.swift")
        let task = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        let result = task.execute()

        switch result {
        case .shouldParse(_, _):
            XCTFail()
        case .skip:
            break
        }
    }

    func test_execute_actualComponent_verifyResult() {
        let fileUrl = fixtureUrl(for: "ComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let task = FileFilterTask(url: fileUrl, exclusionSuffixes: [])

        let result = task.execute()

        switch result {
        case .shouldParse(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }
}
