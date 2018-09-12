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

/// A task that checks the various aspects of a file, including its content
/// to determine if the file needs to be parsed for AST. If the file should
/// This task extends the Needle `FileFilterTask` to support pluginized and
/// non-core component types.
class PluginizedFileFilterTask: AbstractTask<FilterResult> {

    /// Initializer.
    ///
    /// - parameter url: The file URL to read from.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If the given URL filename's suffix matches any in the
    /// this list, the URL will be excluded.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If the given URL's path contains any elements in this list, the
    /// URL will be excluded.
    init(url: URL, exclusionSuffixes: [String], exclusionPaths: [String]) {
        self.url = url
        self.exclusionSuffixes = exclusionSuffixes
        self.exclusionPaths = exclusionPaths
    }

    /// Execute the task and returns the filter result indicating if the file
    /// should be parsed.
    ///
    /// - returns: The `FilterResult`.
    override func execute() -> FilterResult {
        let urlFilter = UrlFilter(url: url, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths)
        if !urlFilter.filter() {
            return FilterResult.skip
        }

        let content = try? String(contentsOf: url)
        if let content = content {
            let contentFilter = PluginizedContentFilter(content: content)
            if contentFilter.filter() {
                return FilterResult.shouldParse(url, content)
            } else {
                return FilterResult.skip
            }
        } else {
            fatalError("Failed to read file at \(url)")
        }
    }

    // MARK: - Private

    private let url: URL
    private let exclusionSuffixes: [String]
    private let exclusionPaths: [String]
}
