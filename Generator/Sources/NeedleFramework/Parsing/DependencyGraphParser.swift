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

/// Errors that can occur during parsing of the dependency graph from Swift sources.
enum DependencyGraphParserError: Error {
    /// Parsing a particular source file timed out.
    case timeout(String)
}

/// The entry utility for the parsing phase. The parser deeply scans a directory and
/// parses the relevant Swift source files, and finally outputs the dependency graph.
class DependencyGraphParser {

    /// Parse all the Swift sources within the directory of given URL, excluding any
    /// file that contains a suffix specified in the given exclusion list. Parsing
    /// sources concurrently using the given executor.
    ///
    /// - parameter rootUrl: The URL of the directory to scan from.
    /// - parameter exclusionSuffixes: If a file name contains a suffix in this list,
    /// the said file is excluded from parsing.
    /// - parameter executor: The executor to use for concurrent processing of files.
    /// - throws: `DependencyGraphParserError.timeout` if parsing a Swift source timed
    /// out.
    // TODO: Pass in the dependency graph data structure so the tasks can contribute to it.
    func parse(from rootUrl: URL, excludingFilesWithSuffixes exclusionSuffixes: [String] = [], using executor: SequenceExecutor) throws {
        var taskHandleTuples = [(handle: SequenceExecutionHandle, fileUrl: URL)]()

        // Enumerate all files and execute parsing sequences concurrently.
        let enumerator = newFileEnumerator(for: rootUrl)
        while let nextObjc = enumerator.nextObject() {
            if let fileUrl = nextObjc as? URL {
                let task = FileFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes)
                let taskHandle = executor.execute(sequenceFrom: task)
                taskHandleTuples.append((taskHandle, fileUrl))
            }
        }

        // Wait for all sequences to finish.
        for tuple in taskHandleTuples {
            do {
                try tuple.handle.await(withTimeout: 30)
            } catch SequenceExecutionError.awaitTimeout {
                throw DependencyGraphParserError.timeout(tuple.fileUrl.absoluteString)
            } catch {
                fatalError("Unhandled task execution error \(error)")
            }
        }
    }

    // MARK: - Private

    private func newFileEnumerator(for rootUrl: URL) -> FileManager.DirectoryEnumerator {
        let errorHandler = { (url: URL, error: Error) -> Bool in
            fatalError("Failed to traverse \(url) with error \(error).")
        }
        if let enumerator = FileManager.default.enumerator(at: rootUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: errorHandler) {
            return enumerator
        } else {
            fatalError("\(rootUrl) does not exist.")
        }
    }
}
