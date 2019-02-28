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

import Basic
import Foundation

/// Utility String extensions.
public extension String {

    /// The SHA256 value of this String.
    public var shortSHA256Value: String {
        return SHA256(self).digestString().substring(with: NSRange(location: 0, length: 20))!
    }

    /// Return the same String with the first character lowercased.
    ///
    /// - returns: The same String with the first character lowercased.
    public func lowercasedFirstChar() -> String {
        let ommitFirstCharIndex = index(after: startIndex)
        return String(self[startIndex]).lowercased() + String(self[ommitFirstCharIndex...])
    }

    /// Returns the substring of the given range.
    ///
    /// - parameter range: The `NSRange` to retrieve substring with.
    /// - returns: The substring if the range is valid. `nil` otherwise.
    public func substring(with range: NSRange) -> String? {
        guard let range = Range(range, in: self) else {
            return nil
        }
        return String(self[range])
    }

    /// Check if this path represents a directory.
    ///
    /// - note: Use this property instead of `URL.isFileURL` property, since
    /// that property only checks for URL scheme, which can be inaccurate.
    public var isDirectory: Bool {
        var isDirectory = ObjCBool(false)
        FileManager.default.fileExists(atPath: self, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    /// Check if this string contains any one of the elements in the
    /// given array.
    ///
    /// - parameter array: The list of elements to check.
    /// - returns: `true` if this string contains at least one element
    /// in the given array. `false` otherwise.
    public func containsAny(in array: [String]) -> Bool {
        for element in array {
            if contains(element) {
                return true
            }
        }
        return false
    }
}

/// Utility URL extensions.
public extension URL {

    /// Initializer.
    ///
    /// - note: This initializer first checks if the given path is a directory.
    /// If so, it initializes a directory URL. Otherwise a URL with the `file`
    /// scheme is initialized. This allows the returned URL to correctly return
    /// the `isFileURL` property.
    /// - parameter path: The `String` path to use.
    public init(path: String) {
        if path.isDirectory {
            self.init(string: path)!
        } else {
            self.init(fileURLWithPath: path)
        }
    }

    /// Check if this URL represents a Swift source file by examining its
    /// file extenson.
    ///
    /// - returns: `true` if the URL is a Swift source file. `false`
    /// otherwise.
    public var isSwiftSource: Bool {
        return pathExtension == "swift"
    }
}
