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

class DependencyGraphParserTests: AbstractParserTests {

    static var allTests = [
        ("test_parse_withTaskCompleteion_verifyEnqueueFileFilterTask", test_parse_withTaskCompleteion_verifyEnqueueFileFilterTask),
        ("test_parse_withTaskCompleteion_verifyResults", test_parse_withTaskCompleteion_verifyResults),
    ]
    
    func test_parse_withTaskCompleteion_verifyEnqueueFileFilterTask() {
        let parser = DependencyGraphParser()
        let fixturesURL = fixtureUrl(for: "")
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]

        let executionHandle = MockExecutionHandle(defaultResult: DependencyGraphNode(components: [], dependencies: [], imports: []))
        executionHandle.awaitHandler = { (timeout: TimeInterval?) in
            XCTAssertNotNil(timeout)
        }

        let executeTaskHandler = { (task: SequencedTask<DependencyGraphNode>) -> SequenceExecutionHandle<DependencyGraphNode> in
            XCTAssertTrue(task is FileFilterTask)
            let filterTask = task as! FileFilterTask
            XCTAssertEqual(filterTask.exclusionSuffixes, ["ha", "yay", "blah"])
            XCTAssertTrue(files.contains(filterTask.url))
            return executionHandle
        }
        let executor = MockSequenceExecutor(executeTaskHandler: executeTaskHandler)

        XCTAssertEqual(executor.executeCallCount, 0)
        XCTAssertEqual(executionHandle.cancelCallCount, 0)
        XCTAssertEqual(executionHandle.awaitCallCount, 0)

        do {
            _ = try parser.parse(from: fixturesURL, excludingFilesWithSuffixes: ["ha", "yay", "blah"], using: executor)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, files.count)
        XCTAssertEqual(executionHandle.cancelCallCount, 0)
        XCTAssertEqual(executionHandle.awaitCallCount, files.count)
    }

    func test_parse_withTaskCompleteion_verifyResults() {
        let parser = DependencyGraphParser()
        let fixturesURL = fixtureUrl(for: "")
        let enumerator = FileManager.default.enumerator(at: fixturesURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: nil)
        let files = enumerator!.allObjects as! [URL]
        let executionHandler = MockExecutionTaskHandler(defaultResult: DependencyGraphNode(components: [], dependencies: [], imports: []))
        let executor = MockSequenceExecutor(executeTaskHandler: executionHandler.execute)

        XCTAssertEqual(executor.executeCallCount, 0)

        do {
            let (components, imports) = try parser.parse(from: fixturesURL, excludingFilesWithSuffixes: ["ha", "yay", "blah"], using: executor)
            let childComponent = components.filter { $0.name == "MyChildComponent" }.first!
            let parentComponent = components.filter { $0.name == "MyComponent" }.first!
            XCTAssertTrue(childComponent.parents.first! == parentComponent)
            XCTAssertEqual(imports, ["import Foundation", "import RIBs", "import RxSwift", "import UIKit", "import Utility"])
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, files.count)
    }
}

class MockSequenceExecutor<T>: SequenceExecutor {

    var executeCallCount = 0

    private let executeTaskHandler: (SequencedTask<T>) -> SequenceExecutionHandle<T>

    init(executeTaskHandler: @escaping (SequencedTask<T>) -> SequenceExecutionHandle<T>) {
        self.executeTaskHandler = executeTaskHandler
    }

    func execute<SequenceResultType>(sequenceFrom task: SequencedTask<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        executeCallCount += 1
        return executeTaskHandler(task as! SequencedTask<T>) as! SequenceExecutionHandle<SequenceResultType>
    }
}

class MockExecutionHandle<T>: SequenceExecutionHandle<T> {

    var awaitCallCount = 0
    var awaitHandler: ((TimeInterval?) -> ())?

    var cancelCallCount = 0
    var cancelHandler: (() -> ())?

    var result: T?

    private let defaultResult: T

    init(defaultResult: T) {
        self.defaultResult = defaultResult
    }

    override func await(withTimeout timeout: TimeInterval?) throws -> T {
        awaitCallCount += 1
        awaitHandler?(timeout)
        return result ?? defaultResult
    }

    override func cancel() {
        cancelCallCount += 1
        cancelHandler?()
    }
}
