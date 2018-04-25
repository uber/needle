//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//

import XCTest
@testable import NeedleFramework

class CountDownLatchTests: XCTestCase {

    static var allTests = [
        ("test_countDown_await_verifyCompletionWithTrue", test_countDown_await_verifyCompletionWithTrue),
        ("test_countDown_await_withTimeout_verifyCompletionWithFalse", test_countDown_await_withTimeout_verifyCompletionWithFalse),
        ("test_countDown_await_verifyDuplicateCountDown_verifyDuplicateAwaitCompletesWithTrue", test_countDown_await_verifyDuplicateCountDown_verifyDuplicateAwaitCompletesWithTrue),
        ("test_multipleAwaitBeforeCountDown_verifyCompletesWithTrue", test_multipleAwaitBeforeCountDown_verifyCompletesWithTrue),
        ("test_multipleAsyncAwaitBeforeCountDown_verifyCompletesWithTrue", test_multipleAsyncAwaitBeforeCountDown_verifyCompletesWithTrue),
    ]

    func test_countDown_await_verifyCompletionWithTrue() {
        let latch = CountDownLatch(count: 3)

        let completion = expectation(description: "completion")

        DispatchQueue.main.async {
            let result = latch.await()
            XCTAssertTrue(result)
            completion.fulfill()
        }

        DispatchQueue.global(qos: .utility).async {
            latch.countDown()
            latch.countDown()
            latch.countDown()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func test_countDown_await_withTimeout_verifyCompletionWithFalse() {
        let latch = CountDownLatch(count: 1)
        let result = latch.await(timeout: 0.001)
        XCTAssertFalse(result)
    }

    func test_countDown_await_verifyDuplicateCountDown_verifyDuplicateAwaitCompletesWithTrue() {
        let latch = CountDownLatch(count: 1)
        latch.countDown()

        latch.countDown()

        let result1 = latch.await()
        XCTAssertTrue(result1)

        let result2 = latch.await()
        XCTAssertTrue(result2)
    }

    func test_multipleAwaitBeforeCountDown_verifyCompletesWithTrue() {
        let latch = CountDownLatch(count: 1)

        let completion = expectation(description: "completion")
        DispatchQueue.main.async {
            let result1 = latch.await()
            XCTAssertTrue(result1)

            let result2 = latch.await()
            XCTAssertTrue(result2)

            completion.fulfill()
        }

        latch.countDown()

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func test_multipleAsyncAwaitBeforeCountDown_verifyCompletesWithTrue() {
        let latch = CountDownLatch(count: 1)

        let awaitExpectation = expectation(description: "await")
        DispatchQueue.global(qos: .utility).async {
            let result = latch.await()
            XCTAssertTrue(result)

            DispatchQueue.global(qos: .utility).async {
                let result = latch.await()
                XCTAssertTrue(result)
                awaitExpectation.fulfill()
            }
        }

        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(0.001 * 1000))
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: deadline) {
            latch.countDown()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
