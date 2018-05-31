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

/// Utility String extensions.
extension String {

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
}
