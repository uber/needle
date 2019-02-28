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
import SourceParsingFramework

/// The result of filtering the source file.
enum FilterResult {
    /// The source URL and content that should be processed further.
    case shouldProcess(URL, String)
    /// The file should be skipped.
    case skip
}

/// A base task implementation that checks the common aspects of a file
/// to determine if the file needs to be parsed for AST.
class BaseFileFilterTask: AbstractTask<FilterResult> {

    /// Initializer.
    ///
    /// - parameter url: The file URL to read from.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If the given URL filename's suffix matches any in the
    /// this list, the URL will be excluded.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If the given URL's path contains any elements in this list, the
    /// URL will be excluded.
    /// - parameter taskId: The tracking task ID to use.
    init(url: URL, exclusionSuffixes: [String], exclusionPaths: [String], taskId: TaskIds) {
        self.url = url
        self.exclusionSuffixes = exclusionSuffixes
        self.exclusionPaths = exclusionPaths
        super.init(id: taskId.rawValue)
    }

    /// Execute the task and returns the filter result indicating if the file
    /// should be parsed.
    ///
    /// - returns: The `FilterResult`.
    /// - throws: Any error occurred during execution.
    final override func execute() throws -> FilterResult {
        let urlFilter = UrlFilter(url: url, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths)
        if !urlFilter.filter() {
            return FilterResult.skip
        }

        let content = try CachedFileReader.instance.content(forUrl: url)
        let filters = self.filters(for: content)
        for filter in filters {
            // If any filter passed, the file needs to be parsed.
            if filter.filter() {
                return FilterResult.shouldProcess(url, content)
            }
        }

        return FilterResult.skip
    }

    /// Create a set of filters for the given file content.
    ///
    /// - parameter content: The file content the returned filters should
    /// be applied on.
    /// - returns: A set of filters to use on the given content.
    func filters(for content: String) -> [FileFilter] {
        return []
    }

    // MARK: - Private

    private let url: URL
    private let exclusionSuffixes: [String]
    private let exclusionPaths: [String]
}
