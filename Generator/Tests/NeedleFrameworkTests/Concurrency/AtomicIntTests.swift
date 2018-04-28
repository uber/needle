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

class AtomicIntTests: XCTestCase {

    static var allTests = [
        ("test_init_verifyInitialValue", test_init_verifyInitialValue),
        ("test_initGetSet_verifySetToNewValue", test_initGetSet_verifySetToNewValue),
        ("test_compareAndSet_verifySettingNewValue", test_compareAndSet_verifySettingNewValue),
        ("test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue", test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue),
        ("test_getAndSet_verifySettingNewValueReturningOldValue", test_getAndSet_verifySettingNewValueReturningOldValue),
        ("test_incrementAndGet_verifyNewValue", test_incrementAndGet_verifyNewValue),
        ("test_decrementAndGet_verifyNewValue", test_decrementAndGet_verifyNewValue),
        ("test_getAndIncrement_verifyNewValue", test_getAndIncrement_verifyNewValue),
        ("test_getAndDecrement_verifyNewValue", test_getAndDecrement_verifyNewValue),
    ]

    func test_init_verifyInitialValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        DispatchQueue.concurrentPerform(iterations: 100000) { _ in
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

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
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

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
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

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
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

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
                XCTAssertFalse(atomicInt.value == initialValue)
                XCTAssertTrue(atomicInt.value == secondValue)
            }
        }
    }

    func test_incrementAndGet_verifyNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        DispatchQueue.concurrentPerform(iterations: 100000) { _ in
            let newValue = atomicInt.incrementAndGet()
            XCTAssertGreaterThan(newValue, initialValue)
        }

        XCTAssertEqual(atomicInt.value, 123+100000)

        let newValue = atomicInt.incrementAndGet()

        XCTAssertEqual(newValue, 123+100000+1)
    }

    func test_decrementAndGet_verifyNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        DispatchQueue.concurrentPerform(iterations: 100000) { _ in
            let newValue = atomicInt.decrementAndGet()
            XCTAssertLessThan(newValue, initialValue)
        }

        XCTAssertEqual(atomicInt.value, 123-100000)

        let newValue = atomicInt.decrementAndGet()

        XCTAssertEqual(newValue, 123-100000-1)
    }

    func test_getAndIncrement_verifyNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        DispatchQueue.concurrentPerform(iterations: 100000) { _ in
            let oldValue = atomicInt.getAndIncrement()
            XCTAssertGreaterThanOrEqual(oldValue, initialValue)
        }

        XCTAssertEqual(atomicInt.value, 123+100000)

        let oldValue = atomicInt.getAndIncrement()

        XCTAssertEqual(oldValue, 123+100000)

        let newValue = atomicInt.value

        XCTAssertEqual(newValue, 123+100000+1)
    }

    func test_getAndDecrement_verifyNewValue() {
        let initialValue = 123
        let atomicInt = AtomicInt(initialValue: initialValue)

        XCTAssertTrue(atomicInt.value == initialValue)

        DispatchQueue.concurrentPerform(iterations: 100000) { _ in
            let oldValue = atomicInt.getAndDecrement()
            XCTAssertLessThanOrEqual(oldValue, initialValue)
        }

        XCTAssertEqual(atomicInt.value, 123-100000)

        let oldValue = atomicInt.getAndDecrement()

        XCTAssertEqual(oldValue, 123-100000)

        let newValue = atomicInt.value

        XCTAssertEqual(newValue, 123-100000-1)
    }
}
