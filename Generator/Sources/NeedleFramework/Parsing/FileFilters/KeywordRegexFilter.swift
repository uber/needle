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

/// A filter that checks if the given content contains the keyword and
/// at least has one match of the given regular expression.
///
/// - note: The keyword is always used first since string matching is
/// more performant. If the content contains the keyword, then regular
/// expression check is performed.
class KeywordRegexFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter content: The content to be filtered.
    /// - parameter keyword: The keyword the content must contain.
    /// - parameter regex: The regular expression the content must have
    /// at least one match.
    init(content: String, keyword: String, regex: Regex) {
        self.content = content
        self.keyword = keyword
        self.regex = regex
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the file content contains the keyword and
    /// at least has one match of the regular expression. `false`
    /// otherwise.
    final func filter() -> Bool {
        // Use simple string matching first since it's more performant.
        if !content.contains(keyword) {
            return false
        }

        // Match actual syntax using Regex.
        if regex.firstMatch(in: content) != nil {
            return true
        }

        return false
    }

    // MARK: - Private

    private let content: String
    private let keyword: String
    private let regex: Regex
}
