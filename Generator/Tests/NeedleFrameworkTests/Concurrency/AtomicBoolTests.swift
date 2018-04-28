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

class AtomicBoolTests: XCTestCase {

    func test_init_verifyInitialValue() {
        let initialValue = true
        let atomicBool = AtomicBool(initialValue: initialValue)

        DispatchQueue.concurrentPerform(iterations: 100000) { _ in
            XCTAssertTrue(atomicBool.value == initialValue)
        }
    }

    func test_initGetSet_verifySetToNewValue() {
        let initialValue = true
        let atomicBool = AtomicBool(initialValue: initialValue)

        XCTAssertTrue(atomicBool.value == initialValue)

        let secondValue = false
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            atomicBool.value = secondValue

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
                XCTAssertFalse(atomicBool.value == initialValue)
                XCTAssertTrue(atomicBool.value == secondValue)
            }
        }
    }

    func test_compareAndSet_verifySettingNewValue() {
        let initialValue = true
        let atomicBool = AtomicBool(initialValue: initialValue)

        XCTAssertTrue(atomicBool.value == initialValue)

        let secondValue = false
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicBool.compareAndSet(expect: initialValue, newValue: secondValue)
            XCTAssertTrue(result)

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
                XCTAssertFalse(atomicBool.value == initialValue)
                XCTAssertTrue(atomicBool.value == secondValue)
            }
        }
    }

    func test_compareAndSet_withFalseExpectValue_verifyNotSettingNewValue() {
        let initialValue = true
        let atomicBool = AtomicBool(initialValue: initialValue)

        XCTAssertTrue(atomicBool.value == initialValue)

        let secondValue = false
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicBool.compareAndSet(expect: false, newValue: secondValue)
            XCTAssertFalse(result)

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
                XCTAssertTrue(atomicBool.value == initialValue)
                XCTAssertFalse(atomicBool.value == secondValue)
            }
        }
    }

    func test_getAndSet_verifySettingNewValueReturningOldValue() {
        let initialValue = true
        let atomicBool = AtomicBool(initialValue: initialValue)

        XCTAssertTrue(atomicBool.value == initialValue)

        let secondValue = false
        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            let result = atomicBool.getAndSet(newValue: secondValue)
            XCTAssertTrue(result == initialValue)
            XCTAssertTrue(atomicBool.value == secondValue)

            DispatchQueue.concurrentPerform(iterations: 100000) { _ in
                XCTAssertFalse(atomicBool.value == initialValue)
                XCTAssertTrue(atomicBool.value == secondValue)
            }
        }
    }
}
