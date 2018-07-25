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

/// Log the given warning message.
///
/// - parameter message: The message to log.
public func warning(_ message: String) {
    #if DEBUG
        UnitTestLogger.instance.log(message)
    #else
        print(message)
    #endif
}

/// A logger that accumulates log messages to support unit testing.
class UnitTestLogger {

    /// The singleton instance.
    static let instance = UnitTestLogger()

    /// The current set of logged messages.
    var messages: [String] {
        return lockedMessages.values
    }

    // NARK: - Private

    private let lockedMessages = LockedArray<String>()

    private init() {}

    fileprivate func log(_ message: String) {
        print(message)
        lockedMessages.append(message)
    }
}

private class LockedArray<ValueType> {

    private let lock = NSLock()
    private var unsafeValues = [ValueType]()

    fileprivate var values: [ValueType] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return Array(unsafeValues)
    }

    fileprivate func append(_ value: ValueType) {
        lock.lock()
        defer {
            lock.unlock()
        }
        unsafeValues.append(value)
    }
}
