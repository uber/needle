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

import Foundation
import libkern

/// A concurrency utility class that ensures read and write-through memory behavior for the
/// wrapped Int. This is not a mutex utility. Concurrent access to this class is allowed.
/// It only guarantees serial time events are consistent in the memory stack, thus preventing
/// stale values.
public class AtomicInt {

    /// The current value.
    public var value: Int {
        get {
            // Create a memory barrier to ensure the entire memory stack is in sync so we
            // can safely retrieve the value. This guarantees the initial value is in sync.
            OSMemoryBarrier()
            return Int(wrappedValue)
        }
        set {
            while true {
                let oldValue = self.value
                if self.compareAndSet(expect: oldValue, newValue: newValue) {
                    break
                }
            }
        }
    }

    /// Initializer.
    ///
    /// - parameter initialValue: The initial value.
    public init(initialValue: Int) {
        wrappedValue = Int64(initialValue)
    }

    /// Atomically sets the new value, if the current value equals the expected value.
    ///
    /// - parameter expect: The expected value to compare against.
    /// - parameter newValue: The new value to set to if the comparison succeeds.
    /// - returns: true if the comparison succeeded and the value is set. false otherwise.
    @discardableResult
    public func compareAndSet(expect: Int, newValue: Int) -> Bool {
        return OSAtomicCompareAndSwap64Barrier(Int64(expect), Int64(newValue), &wrappedValue)
    }

    /// Atomically increment the value and retrieve the new value.
    ///
    /// - returns: The new value after incrementing.
    @discardableResult
    public func incrementAndGet() -> Int {
        let result = OSAtomicIncrement64Barrier(&wrappedValue)
        return Int(result)
    }

    /// Atomically decrement the value and retrieve the new value.
    ///
    /// - returns: The new value after decrementing.
    @discardableResult
    public func decrementAndGet() -> Int {
        let result = OSAtomicDecrement64Barrier(&wrappedValue)
        return Int(result)
    }

    /// Atomically increment the value and retrieve the old value.
    ///
    /// - returns: The old value before incrementing.
    @discardableResult
    public func getAndIncrement() -> Int {
        while true {
            let oldValue = self.value
            let newValue = oldValue + 1
            if self.compareAndSet(expect: oldValue, newValue: newValue) {
                return oldValue
            }
        }
    }

    /// Atomically decrement the value and retrieve the old value.
    ///
    /// - returns: The old value before decrementing.
    @discardableResult
    public func getAndDecrement() -> Int {
        while true {
            let oldValue = self.value
            let newValue = oldValue - 1
            if self.compareAndSet(expect: oldValue, newValue: newValue) {
                return oldValue
            }
        }
    }

    /// Atomically sets to the given new value and returns the old value.
    ///
    /// - parameter newValue: The new value to set to.
    /// - returns: The old value.
    @discardableResult
    public func getAndSet(newValue: Int) -> Int {
        while true {
            let oldValue = self.value
            if compareAndSet(expect: oldValue, newValue: newValue) {
                return oldValue
            }
        }
    }

    // MARK: - Private

    private var wrappedValue: Int64
}
