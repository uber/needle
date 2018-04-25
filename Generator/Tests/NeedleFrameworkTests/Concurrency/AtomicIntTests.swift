//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//

import XCTest
@testable import NeedleFramework

class AtomicIntTests: XCTestCase {

    static var allTests = [
        ("test_init_verifyInitialValue", test_init_verifyInitialValue),
        ("test_initGetSet_verifySetToNewValue", test_initGetSet_verifySetToNewValue),
        ("test_compareAndSet_verifySettingNewValue", test_compareAndSet_verifySettingNewValue),
        ("test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue", test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue),
        ("test_getAndSet_verifySettingNewValueReturningOldValue", test_getAndSet_verifySettingNewValueReturningOldValue),
    ]

    func test_init_verifyInitialValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            XCTAssertTrue(atomicInt.value == initialValue)
        }
    }

    func test_initGetSet_verifySetToNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        let secondValue = 7634

        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            atomicInt.value = secondValue

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertFalse(atomicInt.value == initialValue)
                XCTAssertTrue(atomicInt.value == secondValue)
            }
        }
    }

    func test_compareAndSet_verifySettingNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        let secondValue = 62345
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicInt.compareAndSet(expect: initialValue, newValue: secondValue)
            XCTAssertTrue(result)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertFalse(atomicInt.value == initialValue)
                XCTAssertTrue(atomicInt.value == secondValue)
            }
        }
    }

    func test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        let secondValue = 823
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicInt.compareAndSet(expect: 293, newValue: secondValue)
            XCTAssertFalse(result)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertTrue(atomicInt.value == initialValue)
                XCTAssertFalse(atomicInt.value == secondValue)
            }
        }
    }

    func test_getAndSet_verifySettingNewValueReturningOldValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        let secondValue = 74653
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicInt.getAndSet(newValue: secondValue)
            XCTAssertTrue(result == initialValue)
            XCTAssertTrue(atomicInt.value == secondValue)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertFalse(atomicInt.value == initialValue)
                XCTAssertTrue(atomicInt.value == secondValue)
            }
        }
    }
}
