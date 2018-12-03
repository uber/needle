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

/// The set of errors the generator can throw.
public enum GeneratorError: Error {
    /// The error with a message.
    case withMessage(String)
}

/// The entry point to Needle's code generator.
public class Generator {

    /// Initializer.
    ///
    /// - parameter sourceKitUtilities: The utilities used to perform
    /// SourceKit operations.
    public init(sourceKitUtilities: SourceKitUtilities) {
        self.sourceKitUtilities = sourceKitUtilities
    }

    /// Parse Swift source files by recurively scanning the given directories
    /// or source files included in the given source list files, excluding
    /// files with specified suffixes. Then generate the necessary dependency
    /// provider code and export to the specified destination path.
    ///
    /// - parameter sourceRootUrls: The directories or text files that contain
    /// a set of Swift source files to parse.
    /// - parameter sourcesListFormatValue: The optional `String` value of the
    /// format used by the sources list file. Use `nil` if the given
    /// `sourceRootPaths` is not a file containing a list of Swift source paths.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If a filename's suffix matches any in the this list,
    /// the file will not be parsed.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If a file's URL path contains any elements in this list, the file
    /// will not be parsed.
    /// - parameter additionalImports: The additional import statements to add
    /// to the ones parsed from source files.
    /// - parameter headerDocPath: The path to custom header doc file to be
    /// included at the top of the generated file.
    /// - parameter destinationPath: The path to export generated code to.
    /// - parameter shouldCollectParsingInfo: `true` if dependency graph
    /// parsing information should be collected as tasks are executed. `false`
    /// otherwise. By collecting execution information, if waiting on the
    /// completion of a task sequence in the dependency parsing phase times out,
    /// the reported error contains the relevant information when the timeout
    /// occurred. The tracking does incur a minor performance cost. This value
    /// defaults to `false`.
    /// - parameter parsingTimeout: The timeout value, in seconds, to use for
    /// waiting on parsing tasks.
    /// - parameter exportingTimeout: The timeout value, in seconds, to use for
    /// waiting on exporting tasks.
    /// - parameter retryParsingOnTimeoutLimit: The maximum number of times
    /// parsing Swift source files should be retried in case of timeouts.
    /// - parameter concurrencyLimit: The maximum number of tasks to execute
    /// concurrently. `nil` if no limit is set.
    /// - throws: `GeneratorError`.
    public final func generate(from sourceRootPaths: [String], withSourcesListFormat sourcesListFormatValue: String? = nil, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, shouldCollectParsingInfo: Bool, parsingTimeout: Double, exportingTimeout: Double, retryParsingOnTimeoutLimit: Int, concurrencyLimit: Int?) throws {
        let sourceRootUrls = sourceRootPaths.map { (path: String) -> URL in
            URL(path: path)
        }
        
        let executor = createExecutor(withName: "Needle.generate", shouldTrackTaskId: shouldCollectParsingInfo, concurrencyLimit: concurrencyLimit)

        var retryParsingCount = 0
        while true {
            do {
                try generate(from: sourceRootUrls, withSourcesListFormat: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, with: additionalImports, headerDocPath, to: destinationPath, using: executor, withParsingTimeout: parsingTimeout, exportingTimeout: exportingTimeout)
                break
            } catch DependencyGraphParserError.timeout(let sourcePath, let taskId) {
                retryParsingCount += 1
                let message = "Parsing Swift source file at \(sourcePath) timed out when executing task with ID \(taskId). SourceKit daemon process status: \(sourceKitUtilities.isSourceKitRunning)."
                if retryParsingCount >= retryParsingOnTimeoutLimit {
                    throw GeneratorError.withMessage(message)
                } else {
                    warning(message)
                    warning("Attempt to retry parsing by killing SourceKitService.")
                    // Killing the SourceKit process instead of issuing a SourceKit shutdown command, since the SourceKit
                    // process is likely hung at this point.
                    let didKill = sourceKitUtilities.killProcess()
                    if !didKill {
                        warning("Failed to kill SourceKitService.")
                    }
                    sourceKitUtilities.initialize()
                }
            } catch DependencyGraphExporterError.timeout(let componentName) {
                throw GeneratorError.withMessage("Generating dependency provider for \(componentName) timed out.")
            } catch DependencyGraphExporterError.unableToWriteFile(let outputFile) {
                throw GeneratorError.withMessage("Failed to export contents to \(outputFile)")
            } catch {
                throw GeneratorError.withMessage("Unknown error \(error).")
            }
        }
    }

    // MARK: - Internal

    func generate(from sourceRootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, using executor: SequenceExecutor, withParsingTimeout parsingTimeout: Double, exportingTimeout: Double) throws {
        let parser = DependencyGraphParser()
        let (components, imports) = try parser.parse(from: sourceRootUrls, withSourcesListFormat: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor, withTimeout: parsingTimeout)
        let exporter = DependencyGraphExporter()
        try exporter.export(components, with: imports + additionalImports, to: destinationPath, using: executor, withTimeout: exportingTimeout, include: headerDocPath)
    }

    // MARK: - Private
    
    private let sourceKitUtilities: SourceKitUtilities

    private func createExecutor(withName name: String, shouldTrackTaskId: Bool, concurrencyLimit: Int?) -> SequenceExecutor {
        #if DEBUG
            return ProcessInfo().environment["SINGLE_THREADED"] != nil ? SerialSequenceExecutor() : ConcurrentSequenceExecutor(name: name, qos: .userInteractive, shouldTrackTaskId: shouldTrackTaskId)
        #else
            return ConcurrentSequenceExecutor(name: name, qos: .userInteractive, shouldTrackTaskId: shouldTrackTaskId, maxConcurrentTasks: concurrencyLimit)
        #endif
    }
}
