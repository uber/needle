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

/// The entry point to Needle's code generator.
public class Generator {

    /// Initializer.
    public init() {}

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
    /// - throws: `GenericError`.
    public final func generate(from sourceRootPaths: [String], withSourcesListFormat sourcesListFormatValue: String? = nil, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, shouldCollectParsingInfo: Bool, parsingTimeout: TimeInterval, exportingTimeout: TimeInterval, retryParsingOnTimeoutLimit: Int, concurrencyLimit: Int?) throws {
        let processor: ProcessorType = .generateSource(additionalImports: additionalImports, 
                                                       headerDocPath: headerDocPath, 
                                                       destinationPath: destinationPath, 
                                                       exportingTimeout: exportingTimeout)
        try processSourceCode(from: sourceRootPaths, 
                              withSourcesListFormat: sourcesListFormatValue, 
                              excludingFilesEndingWith: exclusionSuffixes, 
                              excludingFilesWithPaths: exclusionPaths, 
                              shouldCollectParsingInfo: shouldCollectParsingInfo, 
                              parsingTimeout: parsingTimeout, 
                              retryParsingOnTimeoutLimit: retryParsingOnTimeoutLimit, 
                              concurrencyLimit: concurrencyLimit,
                              processorType: processor)
    }

    /// Parse Swift source files by recurively scanning the given directories
    /// or source files included in the given source list files, excluding
    /// files with specified suffixes. Then print the static dependency tree starting at RootComponent.
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
    /// - parameter shouldCollectParsingInfo: `true` if dependency graph
    /// parsing information should be collected as tasks are executed. `false`
    /// otherwise. By collecting execution information, if waiting on the
    /// completion of a task sequence in the dependency parsing phase times out,
    /// the reported error contains the relevant information when the timeout
    /// occurred. The tracking does incur a minor performance cost. This value
    /// defaults to `false`.
    /// - parameter parsingTimeout: The timeout value, in seconds, to use for
    /// waiting on parsing tasks.
    /// - parameter retryParsingOnTimeoutLimit: The maximum number of times
    /// parsing Swift source files should be retried in case of timeouts.
    /// - parameter concurrencyLimit: The maximum number of tasks to execute
    /// concurrently. `nil` if no limit is set.
    /// - throws: `GenericError`.
    public final func printDependencyTree(from sourceRootPaths: [String],
                                          withSourcesListFormat sourcesListFormatValue: String? = nil, 
                                          excludingFilesEndingWith exclusionSuffixes: [String], 
                                          excludingFilesWithPaths exclusionPaths: [String],
                                          shouldCollectParsingInfo: Bool, 
                                          parsingTimeout: TimeInterval,
                                          retryParsingOnTimeoutLimit: Int, 
                                          concurrencyLimit: Int?,
                                          rootComponentName: String) throws {
        let processor: ProcessorType = .printDIStructure(rootComponentName: rootComponentName)
        try processSourceCode(from: sourceRootPaths, 
                              withSourcesListFormat: sourcesListFormatValue, 
                              excludingFilesEndingWith: exclusionSuffixes, 
                              excludingFilesWithPaths: exclusionPaths, 
                              shouldCollectParsingInfo: shouldCollectParsingInfo, 
                              parsingTimeout: parsingTimeout, 
                              retryParsingOnTimeoutLimit: retryParsingOnTimeoutLimit, 
                              concurrencyLimit: concurrencyLimit,
                              processorType: processor)
    }

    // MARK: - Internal

    func generate(from sourceRootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String, using executor: SequenceExecutor, withParsingTimeout parsingTimeout: TimeInterval, exportingTimeout: TimeInterval) throws {
        let parser = DependencyGraphParser()
        let (components, imports) = try parser.parse(from: sourceRootUrls, withSourcesListFormat: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor, withTimeout: parsingTimeout)
        let exporter = DependencyGraphExporter()
        try exporter.export(components, with: imports + additionalImports, to: destinationPath, using: executor, withTimeout: exportingTimeout, include: headerDocPath)
    }

    // MARK: - Private
    
    private enum ProcessorType {
        case generateSource(additionalImports: [String], headerDocPath: String?, destinationPath: String, exportingTimeout: TimeInterval)
        case printDIStructure(rootComponentName: String)
    }

    private func createExecutor(withName name: String, shouldTrackTaskId: Bool, concurrencyLimit: Int?) -> SequenceExecutor {
        #if DEBUG
            return ProcessInfo().environment["SINGLE_THREADED"] != nil ? ImmediateSerialSequenceExecutor() : ConcurrentSequenceExecutor(name: name, qos: .userInteractive, shouldTrackTaskId: shouldTrackTaskId, maxConcurrentTasks: concurrencyLimit)
        #else
            return ConcurrentSequenceExecutor(name: name, qos: .userInteractive, shouldTrackTaskId: shouldTrackTaskId, maxConcurrentTasks: concurrencyLimit)
        #endif
    }

    private func processSourceCode(from sourceRootPaths: [String], 
                                   withSourcesListFormat sourcesListFormatValue: String? = nil, 
                                   excludingFilesEndingWith exclusionSuffixes: [String], 
                                   excludingFilesWithPaths exclusionPaths: [String], 
                                   shouldCollectParsingInfo: Bool, 
                                   parsingTimeout: TimeInterval,
                                   retryParsingOnTimeoutLimit: Int, 
                                   concurrencyLimit: Int?,
                                   processorType: ProcessorType) throws {
        let sourceRootUrls = sourceRootPaths.map { (path: String) -> URL in
            URL(path: path)
        }
        
        let executor = createExecutor(withName: "Needle.generate", shouldTrackTaskId: shouldCollectParsingInfo, concurrencyLimit: concurrencyLimit)

        var retryParsingCount = 0
        while true {
            do {
                switch processorType {
                    case .generateSource(let additionalImports, let headerDocPath, let destinationPath, let exportingTimeout):
                        try generate(from: sourceRootUrls, withSourcesListFormat: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, with: additionalImports, headerDocPath, to: destinationPath, using: executor, withParsingTimeout: parsingTimeout, exportingTimeout: exportingTimeout)
                    case .printDIStructure(let rootComponentName):
                        try printDIStructure(from : sourceRootUrls,
                                             withSourcesListFormat: sourcesListFormatValue,
                                             excludingFilesEndingWith: exclusionSuffixes,
                                             excludingFilesWithPaths: exclusionPaths,
                                             withExecutor: executor,
                                             withParsingTimeout: parsingTimeout,
                                             withRootComponentName: rootComponentName)
                }
                break
            } catch DependencyGraphParserError.timeout(let sourcePath, let taskId) {
                retryParsingCount += 1
                let message = "Parsing Swift source file at \(sourcePath) timed out when executing task with ID \(taskId)."
                if retryParsingCount >= retryParsingOnTimeoutLimit {
                    throw GenericError.withMessage(message)
                }
            } catch {
                throw error
            }
        }
    }

    private func printDIStructure(from sourceRootUrls: [URL],
                                  withSourcesListFormat sourcesListFormatValue: String? = nil, 
                                  excludingFilesEndingWith exclusionSuffixes: [String], 
                                  excludingFilesWithPaths exclusionPaths: [String], 
                                  withExecutor executor: SequenceExecutor,
                                  withParsingTimeout parsingTimeout: TimeInterval,
                                  withRootComponentName rootComponentName: String) throws {
        let parser = DependencyGraphParser()
        let (components, _) = try parser.parse(from: sourceRootUrls, withSourcesListFormat: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor, withTimeout: parsingTimeout)
        let printer = DependencyGraphPrinter(components: components)
        printer.printDIStructure(withRootComponentName: rootComponentName)
    }
}
