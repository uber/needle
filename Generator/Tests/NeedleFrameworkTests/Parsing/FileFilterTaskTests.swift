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

class FileFilterTaskTests: XCTestCase {
    
    func test_execute_nonSwiftSource_verifyFilter() {
        let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/NonSwift.json")
        let task = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        let nextTask = task.execute()
        XCTAssertNil(nextTask)
    }

    func test_execute_excludedSuffix_verifyFilter() {
        let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/ComponentSample.swift")
        let excludeSuffixTask = FileFilterTask(url: fixturesURL, exclusionSuffixes: ["Sample"])

        var nextTask = excludeSuffixTask.execute()
        XCTAssertNil(nextTask)

        let includeSuffixTask = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        nextTask = includeSuffixTask.execute()
        XCTAssertNotNil(nextTask)
    }

    func test_execute_nonNeedleComponent_verifyFilter() {
        let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/NonNeedleComponent.swift")
        let task = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        let nextTask = task.execute()
        XCTAssertNil(nextTask)
    }

    func test_execute_nonInheritanceComponent_verifyFilter() {
        let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/NonInheritanceComponent.swift")
        let task = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        let nextTask = task.execute()
        XCTAssertNil(nextTask)
    }

    func test_execute_actualComponent_verifyNextTask() {
        let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/ComponentSample.swift")
        let task = FileFilterTask(url: fixturesURL, exclusionSuffixes: [])

        let nextTask = task.execute()
        XCTAssertNotNil(nextTask)
    }
}
