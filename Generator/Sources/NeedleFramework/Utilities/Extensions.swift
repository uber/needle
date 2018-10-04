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
extension String {

    /// The SHA256 value of this String.
    var shortSHA256Value: String {
        return SHA256(self).digestString().substring(with: NSRange(location: 0, length: 20))!
    }

    /// Return the same String with the first character lowercased.
    ///
    /// - returns: The same String with the first character lowercased.
    func lowercasedFirstChar() -> String {
        let ommitFirstCharIndex = index(after: startIndex)
        return String(self[startIndex]).lowercased() + String(self[ommitFirstCharIndex...])
    }

    /// Returns the substring of the given range.
    ///
    /// - parameter range: The `NSRange` to retrieve substring with.
    /// - returns: The substring if the range is valid. `nil` otherwise.
    func substring(with range: NSRange) -> String? {
        guard let range = Range(range, in: self) else {
            return nil
        }
        return String(self[range])
    }

    /// Check if this path represents a directory.
    ///
    /// - note: Use this property instead of `URL.isFileURL` property, since
    /// that property only checks for URL scheme, which can be inaccurate.
    var isDirectory: Bool {
        var isDirectory = ObjCBool(false)
        FileManager.default.fileExists(atPath: self, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}

/// Utility URL extensions.
extension URL {

    /// Initializer.
    ///
    /// - note: This initializer first checks if the given path is a directory.
    /// If so, it initializes a directory URL. Otherwise a URL with the `file`
    /// scheme is initialized. This allows the returned URL to correctly return
    /// the `isFileURL` property.
    /// - parameter path: The `String` path to use.
    init(path: String) {
        if path.isDirectory {
            self.init(string: path)!
        } else {
            self.init(fileURLWithPath: path)
        }
    }
}
