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

class AtomicReferenceTests: XCTestCase {

    static var allTests = [
        ("test_init_verifyInitialValue", test_init_verifyInitialValue),
        ("test_initGetSet_verifySetToNewValue", test_initGetSet_verifySetToNewValue),
        ("test_compareAndSet_verifySettingNewValue", test_compareAndSet_verifySettingNewValue),
        ("test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue", test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue),
        ("test_compareAndSet_withNil_verifySettingNewValue", test_compareAndSet_withNil_verifySettingNewValue),
        ("test_getAndSet_verifySettingNewValueReturningOldValue", test_getAndSet_verifySettingNewValueReturningOldValue),
        ("test_compareAndSet_initialNilThenResetToNil_verifySuccess", test_compareAndSet_initialNilThenResetToNil_verifySuccess),
    ]

    func test_init_verifyInitialValue() {
        let initialValue = NSObject()
        let atomicRef = AtomicReference<NSObject>(initialValue: initialValue)

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            XCTAssertTrue(atomicRef.value === initialValue)
        }
    }

    func test_initGetSet_verifySetToNewValue() {
        let initialValue = NSObject()
        let atomicRef = AtomicReference<NSObject>(initialValue: initialValue)

        XCTAssertTrue(atomicRef.value === initialValue)

        let secondValue = NSObject()

        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            atomicRef.value = secondValue

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertFalse(atomicRef.value === initialValue)
                XCTAssertTrue(atomicRef.value === secondValue)
            }
        }
    }

    func test_compareAndSet_verifySettingNewValue() {
        let initialValue = NSObject()
        let atomicRef = AtomicReference<NSObject>(initialValue: initialValue)

        XCTAssertTrue(atomicRef.value === initialValue)

        let secondValue = NSObject()
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicRef.compareAndSet(expect: initialValue, newValue: secondValue)
            XCTAssertTrue(result)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertFalse(atomicRef.value === initialValue)
                XCTAssertTrue(atomicRef.value === secondValue)
            }
        }
    }

    func test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue() {
        let initialValue = NSObject()
        let atomicRef = AtomicReference<NSObject>(initialValue: initialValue)

        XCTAssertTrue(atomicRef.value === initialValue)

        let secondValue = NSObject()
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicRef.compareAndSet(expect: NSObject(), newValue: secondValue)
            XCTAssertFalse(result)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertTrue(atomicRef.value === initialValue)
                XCTAssertFalse(atomicRef.value === secondValue)
            }
        }
    }

    func test_compareAndSet_withNil_verifySettingNewValue() {
        let atomicRef = AtomicReference<String?>(initialValue: nil)

        XCTAssertNil(atomicRef.value)

        let secondValue = "What?!"
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicRef.compareAndSet(expect: nil, newValue: secondValue)
            XCTAssertTrue(result)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertNotNil(atomicRef.value)
                XCTAssertEqual(atomicRef.value, secondValue)
            }
        }
    }

    func test_getAndSet_verifySettingNewValueReturningOldValue() {
        let initialValue = NSObject()
        let atomicRef = AtomicReference<NSObject>(initialValue: initialValue)

        XCTAssertTrue(atomicRef.value === initialValue)

        let secondValue = NSObject()
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicRef.getAndSet(newValue: secondValue)
            XCTAssertTrue(result === initialValue)
            XCTAssertTrue(atomicRef.value === secondValue)

            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                XCTAssertFalse(atomicRef.value === initialValue)
                XCTAssertTrue(atomicRef.value === secondValue)
            }
        }
    }

    func test_compareAndSet_initialNilThenResetToNil_verifySuccess() {
        let atomicRef = AtomicReference<NSObject?>(initialValue: nil)
        let firstValue = NSObject()
        var result = atomicRef.compareAndSet(expect: nil, newValue: firstValue)
        XCTAssertTrue(result)
        XCTAssertTrue(atomicRef.value === firstValue)

        atomicRef.value = nil
        XCTAssertNil(atomicRef.value)

        let secondValue = NSObject()
        result = atomicRef.compareAndSet(expect: nil, newValue: secondValue)
        XCTAssertTrue(result)
        XCTAssertTrue(atomicRef.value === secondValue)

        let thirdValue = NSObject()
        atomicRef.value = thirdValue
        XCTAssertTrue(atomicRef.value === thirdValue)

        result = atomicRef.compareAndSet(expect: thirdValue, newValue: nil)
        XCTAssertTrue(result)
        XCTAssertNil(atomicRef.value)
    }
}
