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

/// A simple wrapper around `NSRegularExpression` to make the API easier to use.
public class Regex {

    /// The backing `NSRegularExpression`.
    public let expression: NSRegularExpression

    /// Initializer.
    ///
    /// - parameter expression: The expression in `String` format.
    public init(_ expression: String) {
        do {
            self.expression = try NSRegularExpression(pattern: expression, options: [])
        } catch {
            fatalError("Could not create NSRegularExpression for expression \(expression).")
        }
    }

    /// Retrieve the first match in the given content.
    ///
    /// - parameter content: The content to check from.
    /// - returns: The first matching result if there is a match. `nil` otherwise.
    public func firstMatch(in content: String) -> NSTextCheckingResult? {
        return expression.firstMatch(in: content, options: [], range: NSRange(location:0, length:content.count))
    }

    /// Retrieve all the matches in the given content.
    ///
    /// - parameter content: The content to check from.
    /// - returns: All the matching results.
    public func matches(in content: String) -> [NSTextCheckingResult] {
        return expression.matches(in: content, options: [], range: NSRange(location:0, length:content.count))
    }
}
