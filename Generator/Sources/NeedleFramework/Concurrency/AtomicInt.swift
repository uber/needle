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

    /// The value that guarantees atomic read and write-through memory behavior.
    public var value: Int {
        get {
            // Create a memory barrier to ensure the entire memory stack is in sync so we
            // can safely retrieve the value. This guarantees the initial value is in sync.
            OSMemoryBarrier()
            return wrappedValue
        }
        set {
            OSMemoryBarrier()
            wrappedValue = newValue
        }
    }

    /// Initializer.
    ///
    /// - parameter initialValue: The initial value.
    public init(initialValue: Int) {
        wrappedValue = initialValue
    }

    /// Atomically sets the new value, if the current value equals the expected value.
    ///
    /// - parameter expect: The expected value to compare against.
    /// - parameter newValue: The new value to set to if the comparison succeeds.
    /// - returns: true if the comparison succeeded and the value is set. false otherwise.
    public func compareAndSet(expect: Int, newValue: Int) -> Bool {
        return OSAtomicCompareAndSwapLongBarrier(expect, newValue, &wrappedValue)
    }

    /// Atomically sets to the given new value and returns the old value.
    ///
    /// - parameter newValue: The new value to set to.
    /// - returns: The old value.
    public func getAndSet(newValue: Int) -> Int {
        while true {
            let oldValue = self.value
            if compareAndSet(expect: oldValue, newValue: newValue) {
                return oldValue
            }
        }
    }

    // MARK: - Private

    private var wrappedValue: Int
}
