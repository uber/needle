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

/// A task that checks the various aspects of a file, including its content to determine
/// if the file needs to be parsed for AST. If the file should be parsed, it returns the
/// `ASTProducerTask` for further processing.
class FileFilterTask: SequencedTask {

    /// The file URL to read from.
    let url: URL
    /// The list of file name suffixes to check from.
    let exclusionSuffixes: [String]

    /// Initializer.
    /// - parameter url: The file URL to read from.
    /// - parameter exclusionSuffixes: The list of file name suffixes to check from. If
    /// the given URL filename's suffix matches any in the this list, the file will not
    /// be parsed.
    init(url: URL, exclusionSuffixes: [String]) {
        self.url = url
        self.exclusionSuffixes = exclusionSuffixes
    }

    /// Execute the task and returns `ASTParserTask` if the file should be parsed.
    ///
    /// - returns: `ASTParserTask` if the file should be parsed. `nil` otherwise.
    func execute() -> SequencedTask? {
        if !isUrlSwiftSource || urlHasExcludedSuffix {
            return nil
        }

        let content = try? String(contentsOf: url)
        if let content = content {
            if shouldParse(content) {
                return ASTProducerTask(sourceUrl: url, sourceContent: content)
            } else {
                return nil
            }
        } else {
            fatalError("Failed to read file at \(url)")
        }
    }

    // MARK: - Private

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

    private func shouldParse(_ content: String) -> Bool {
        // Use simple string matching first since it's more performant.
        if !content.contains("Component") {
            return false
        }

        // Match actual component inheritance using Regex.
        let containsComponentInheritance = (Regex("Component *<").firstMatch(in: content) != nil)
        return containsComponentInheritance
    }
}
