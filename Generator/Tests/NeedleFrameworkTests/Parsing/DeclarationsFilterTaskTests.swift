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

class DeclarationsFilterTaskTests: AbstractParserTests {

    func test_execute_nonSwiftSource_verifyFilter() {
        let fileUrl = fixtureUrl(for: "NonSwift.json")
        let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()
        switch result {
        case .shouldProcess(_, _):
            XCTFail()
        case .skip:
            break
        }
    }

    func test_execute_excludedSuffix_verifyFilter() {
        let fileUrl = fixtureUrl(for: "ComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let excludeSuffixTask = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: ["Sample"], exclusionPaths: [])

        var result = try! excludeSuffixTask.execute()

        switch result {
        case .shouldProcess(_, _):
            XCTFail()
        case .skip:
            break
        }

        let includeSuffixTask = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        result = try! includeSuffixTask.execute()

        switch result {
        case .shouldProcess(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_actualComponent_verifyResult() {
        let fileUrl = fixtureUrl(for: "ComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()

        switch result {
        case .shouldProcess(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_onlyDependency_verifyResult() {
        let fileUrl = fixtureUrl(for: "OnlyDependency.swift")
        let content = try! String(contentsOf: fileUrl)
        let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()

        switch result {
        case .shouldProcess(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_namespacedComponent_verifyResult() {
        let fileUrl = fixtureUrl(for: "NamespacedComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()

        switch result {
        case .shouldProcess(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_rootComponent_verifyResult() {
        let fileUrl = fixtureUrl(for: "RootComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()

        switch result {
        case .shouldProcess(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_namespacedRootComponent_verifyResult() {
        let fileUrl = fixtureUrl(for: "NamespacedRootComponentSample.swift")
        let content = try! String(contentsOf: fileUrl)
        let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()

        switch result {
        case .shouldProcess(let sourceUrl, let sourceContent):
            XCTAssertEqual(sourceUrl, fileUrl)
            XCTAssertEqual(sourceContent, content)
        case .skip:
            XCTFail()
        }
    }
}
