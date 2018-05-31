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

class SequenceExecutorTests: XCTestCase {

    static var allTests = [
        ("test_executeSequence_withSingle_verifyConcurrency", test_executeSequence_withSingle_verifyConcurrency),
        ("test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency", test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency),
        ("test_executeSequence_withTerminatingSequence_noTimeout_verifyAwaitResult_verifyConcurrency", test_executeSequence_withTerminatingSequence_noTimeout_verifyAwaitResult_verifyConcurrency),
        ("test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout", test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout),
    ]

    func test_executeSequence_withSingle_verifyConcurrency() {
        let executor = SequenceExecutorImpl(name: "test_executeSequence_withSingle_verifyConcurrency")

        var threadHashes = [Int: Int]()
        let threadHashesLock = NSRecursiveLock()

        for i in 0 ..< 10000 {
            let didComplete = expectation(description: "task-\(i)")
            let task = MockSelfRepeatingTask {
                threadHashesLock.lock()
                let hash = Thread.current.hash
                threadHashes[hash] = hash
                threadHashesLock.unlock()

                didComplete.fulfill()

                return 68281
            }
            _ = executor.execute(sequenceFrom: task)
        }

        waitForExpectations(timeout: 3, handler: nil)

        threadHashesLock.lock()
        XCTAssertGreaterThan(threadHashes.count, 4)
        threadHashesLock.unlock()
    }

    func test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency() {
        let executor = SequenceExecutorImpl(name: "test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency")

        var executionCount = 0
        var threadHashes = [Int: Int]()
        let threadHashesLock = NSRecursiveLock()
        let sequencedTask = MockSelfRepeatingTask {
            threadHashesLock.lock()
            let hash = Thread.current.hash
            threadHashes[hash] = hash
            executionCount += 1
            threadHashesLock.unlock()

            return nil
        }

        let handle = executor.execute(sequenceFrom: sequencedTask)

        Thread.sleep(forTimeInterval: 1)

        handle.cancel()

        threadHashesLock.lock()
        XCTAssertGreaterThan(threadHashes.count, 1)
        XCTAssertGreaterThanOrEqual(executionCount, threadHashes.count)
        threadHashesLock.unlock()
    }

    func test_executeSequence_withTerminatingSequence_noTimeout_verifyAwaitResult_verifyConcurrency() {
        let executor = SequenceExecutorImpl(name: "test_executeSequence_withTerminatingSequence_noTimeout_verifyAwait_verifyConcurrency")

        var executionCount = 0
        var threadHashes = [Int: Int]()
        let threadHashesLock = NSRecursiveLock()
        let sequencedTask = MockSelfRepeatingTask {
            threadHashesLock.lock()
            defer {
                threadHashesLock.unlock()
            }
            let hash = Thread.current.hash
            threadHashes[hash] = hash
            executionCount += 1

            return executionCount > 100000 ? 17823781 : nil
        }

        let handle = executor.execute(sequenceFrom: sequencedTask)

        do {
            let result = try handle.await(withTimeout: nil)
            XCTAssertEqual(result, 17823781)
        } catch {
            XCTFail("Waiting for execution completion failed.")
        }

        threadHashesLock.lock()
        XCTAssertGreaterThan(threadHashes.count, 1)
        XCTAssertGreaterThanOrEqual(executionCount, threadHashes.count)
        threadHashesLock.unlock()
    }

    func test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout() {
        let executor = SequenceExecutorImpl(name: "test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout")

        let sequencedTask = MockSelfRepeatingTask {
            return nil
        }

        let handle = executor.execute(sequenceFrom: sequencedTask)

        var didThrowError = false
        let startTime = CACurrentMediaTime()
        do {
            _ = try handle.await(withTimeout: 0.5)
        } catch SequenceExecutionError.awaitTimeout {
            didThrowError = true
            let endTime = CACurrentMediaTime()
            XCTAssertTrue((endTime - startTime) >= 0.5)
        } catch {
            XCTFail("Incorrect error thrown: \(error)")
        }

        XCTAssertTrue(didThrowError)
    }
}

class MockSelfRepeatingTask: SequencedTask<Int> {

    private let execution: () -> Int?

    init(execution: @escaping () -> Int?) {
        self.execution = execution
    }

    override func execute() -> ExecutionResult<Int> {
        let result = execution()
        if let result = result {
            return .endOfSequence(result)
        } else {
            return .continueSequence(MockSelfRepeatingTask(execution: self.execution))
        }
    }
}
