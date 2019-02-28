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

/// A filter that performs checks based on URL content.
public class UrlFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter url: The file URL to read from.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If the given URL filename's suffix matches any in the
    /// this list, the URL will be excluded.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If the given URL's path contains any elements in this list, the
    /// URL will be excluded.
    public init(url: URL, exclusionSuffixes: [String], exclusionPaths: [String]) {
        self.url = url
        self.exclusionSuffixes = exclusionSuffixes
        self.exclusionPaths = exclusionPaths
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the URL should be parsed. `false` otherwise.
    public func filter() -> Bool {
        if !url.isSwiftSource || urlHasExcludedSuffix || urlHasExcludedPath {
            return false
        }
        return true
    }

    // MARK: - Private

    private let url: URL
    private let exclusionSuffixes: [String]
    private let exclusionPaths: [String]

    private var urlHasExcludedSuffix: Bool {
        let name = url.deletingPathExtension().lastPathComponent
        for suffix in exclusionSuffixes {
            if name.hasSuffix(suffix) {
                return true
            }
        }
        return false
    }

    private var urlHasExcludedPath: Bool {
        let path = url.absoluteString
        for component in exclusionPaths {
            if path.contains(component) {
                return true
            }
        }
        return false
    }
}
