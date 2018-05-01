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

class DependencyGraphParserTests: XCTestCase {
    
    func test_parse_withTaskCompleteion_verifyEnqueueFileFilterTask() {
        let parser = DependencyGraphParser()
        let fixturesURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/")
        print(fixturesURL)
        let executionHandle = MockExecutionHandle()
        executionHandle.awaitHandler = { (timeout: TimeInterval?) in
            XCTAssertNotNil(timeout)
        }
        let executeTaskHandler = { (task: SequencedTask) -> SequenceExecutionHandle in
            XCTAssertTrue(task is FileFilterTask)
            return executionHandle
        }
        let executor = MockSequenceExecutor(executeTaskHandler: executeTaskHandler)

        XCTAssertEqual(executor.executeCallCount, 0)
        XCTAssertEqual(executionHandle.cancelCallCount, 0)
        XCTAssertEqual(executionHandle.awaitCallCount, 0)

        do {
            try parser.parse(from: fixturesURL, using: executor)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(executor.executeCallCount, 2)
        XCTAssertEqual(executionHandle.cancelCallCount, 0)
        XCTAssertEqual(executionHandle.awaitCallCount, 2)
    }
}

class MockSequenceExecutor: SequenceExecutor {

    var executeCallCount = 0

    private let executeTaskHandler: (SequencedTask) -> SequenceExecutionHandle

    init(executeTaskHandler: @escaping (SequencedTask) -> SequenceExecutionHandle) {
        self.executeTaskHandler = executeTaskHandler
    }

    func execute(sequenceFrom task: SequencedTask) -> SequenceExecutionHandle {
        executeCallCount += 1
        return executeTaskHandler(task)
    }
}

class MockExecutionHandle: SequenceExecutionHandle {

    var awaitCallCount = 0
    var awaitHandler: ((TimeInterval?) -> ())?

    var cancelCallCount = 0
    var cancelHandler: (() -> ())?

    func await(withTimeout timeout: TimeInterval?) throws {
        awaitCallCount += 1
        awaitHandler?(timeout)
    }

    func cancel() {
        cancelCallCount += 1
        cancelHandler?()
    }
}
