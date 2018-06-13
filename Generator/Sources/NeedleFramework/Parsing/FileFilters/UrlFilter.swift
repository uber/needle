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
class UrlFilter: FileFilter {

    /// Initializer.
    ///
    /// - parameter url: The file URL to read from.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If the given URL filename's suffix matches any in the
    /// this list, the file will not be parsed.
    init(url: URL, exclusionSuffixes: [String]) {
        self.url = url
        self.exclusionSuffixes = exclusionSuffixes
    }

    /// Execute the filter.
    ///
    /// - returns: `true` if the URL is a Swift source file and its file
    /// name suffix is not in the exclusion list.
    func filter() -> Bool {
        if !isUrlSwiftSource || urlHasExcludedSuffix {
            return false
        }
        return true
    }

    // MARK: - Private

    private let url: URL
    private let exclusionSuffixes: [String]

    private var isUrlSwiftSource: Bool {
        return url.pathExtension == "swift"
    }

    private var urlHasExcludedSuffix: Bool {
        let name = url.deletingPathExtension().lastPathComponent
        for suffix in exclusionSuffixes {
            if name.hasSuffix(suffix) {
                return true
            }
        }
        return false
    }
}
