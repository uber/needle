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

class ComponentInitsFilterTaskTests: AbstractParserTests {

    func test_execute_noInits_verifyFilter() {
        let fileUrl = fixtureUrl(for: "ChildComponent.swift")
        let task = ComponentInitsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()
        switch result {
        case .shouldProcess(_, _):
            XCTFail()
        case .skip:
            break
        }
    }

    func test_execute_hasValidInits_verifyFilter() {
        let fileUrl = fixtureUrl(for: "ValidInits.swift")
        let expectedContent = try! String(contentsOf: fileUrl)
        let task = ComponentInitsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

        let result = try! task.execute()
        switch result {
        case .shouldProcess(let url, let content):
            XCTAssertEqual(fileUrl, url)
            XCTAssertEqual(content, expectedContent)
        case .skip:
            XCTFail()
        }
    }

    func test_execute_hasInvalidInits_verifyFilter() {
        for i in 1 ..< 6 {
            let fileUrl = fixtureUrl(for: "InvalidInits/InvalidInits\(i).swift")
            let expectedContent = try! String(contentsOf: fileUrl)
            let task = ComponentInitsFilterTask(url: fileUrl, exclusionSuffixes: [], exclusionPaths: [])

            let result = try! task.execute()
            switch result {
            case .shouldProcess(let url, let content):
                XCTAssertEqual(fileUrl, url)
                XCTAssertEqual(content, expectedContent)
            case .skip:
                XCTFail()
            }
        }
    }
}
