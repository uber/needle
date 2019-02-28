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

import Concurrency
import Foundation

/// The various levels of logging.
public enum LoggingLevel: Int {
    /// The most verbose level including all logs.
    case debug
    /// The level that includes everything except debug logs.
    case info
    /// The level that only includes warning logs.
    case warning

    /// An cute emoticon describing the log level.
    public var emoticon: String {
        switch self {
        case .debug: return "🐞"
        case .info: return "📋"
        case .warning: return "❗️"
        }
    }

    /// Retrieve the logging level based on the given String value.
    ///
    /// - parameter value: The `String` value to parse from.
    /// - returns: The corresponding `LoggingLevel` if there is one.
    /// `nil` otherwise.
    public static func level(from value: String) -> LoggingLevel? {
        switch value {
        case "debug": return .debug
        case "info": return .info
        case "warning": return .warning
        default: return nil
        }
    }
}

// Use `AtomicInt` since logging may be invoked from multiple threads.
private let minLoggingOutputLevel = AtomicInt(initialValue: LoggingLevel.warning.rawValue)

/// Set the minimum logging level required to output a message.
///
/// - parameter minLoggingOutputLevel: The minimum logging level.
public func set(minLoggingOutputLevel level: LoggingLevel) {
    minLoggingOutputLevel.value = level.rawValue
}

/// Log the given message at the `debug` level.
///
/// - parameter message: The message to log.
/// - note: The mesasge is only logged if the current `minLoggingOutputLevel`
/// is set at or below the `debug` level.
public func debug(_ message: String) {
    log(message, atLevel: .debug)
}

/// Log the given message at the `info` level.
///
/// - parameter message: The message to log.
/// - note: The mesasge is only logged if the current `minLoggingOutputLevel`
/// is set at or below the `info` level.
public func info(_ message: String) {
    log(message, atLevel: .info)
}

/// Log the given message at the `warning` level.
///
/// - parameter message: The message to log.
/// - note: The mesasge is only logged if the current `minLoggingOutputLevel`
/// is set at or below the `warning` level.
public func warning(_ message: String) {
    log(message, atLevel: .warning)
}

private func log(_ message: String, atLevel level: LoggingLevel) {
    #if DEBUG
        UnitTestLogger.instance.log(message, at: level)
    #endif

    if level.rawValue >= minLoggingOutputLevel.value {
        print("\(level.emoticon) \(message)")
    }
}

// MARK: - Unit Test

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

    fileprivate func log(_ message: String, at level: LoggingLevel) {
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
