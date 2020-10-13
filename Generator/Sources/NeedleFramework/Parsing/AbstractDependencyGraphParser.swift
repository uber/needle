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

/// Errors that can occur during parsing of the dependency graph from
/// Swift sources.
enum DependencyGraphParserError: Error {
    /// Parsing a particular source file timed out. The associated values
    /// are the path of the file being parsed and the ID of the task that
    /// was being executed when the timeout occurred.
    case timeout(String, Int)
}

/// The base implementation of parsing a set of Swift source files for
/// dependency graph models.
class AbstractDependencyGraphParser {
    private var allFileUrls: [URL] = []

    /// Execute a set of tasks on the files within the given root URLs
    /// and return their execution handles.
    ///
    /// - parameter rootUrls: The URLs of the directories to scan from.
    /// - parameter sourcesListFormatValue: The optional `String` value of
    /// the format used by the sources list file. If `nil` and the the given
    /// `rootUrl` is a file containing a list of Swift source paths, the
    /// `SourcesListFileFormat.newline` format is used. If the given `rootUrl`
    /// is not a file containing a list of Swift source paths, this value is
    /// ignored.
    /// - parameter execution: The logic to invoke for each file.
    /// - returns: The set of execution handles returned by the given logic
    /// closure and their corresponding file URLs.
    /// - throws: If any error occurred during execution.
    func executeAndCollectTaskHandles<ResultType>(with rootUrls: [URL], sourcesListFormatValue: String?, execution: (URL) -> SequenceExecutionHandle<ResultType>) throws -> [(SequenceExecutionHandle<ResultType>, URL)] {
        var urlHandles = [(SequenceExecutionHandle<ResultType>, URL)]()
        
        // Enumerate all files and execute parsing sequences concurrently.
        try collectFileUrlsIfNeeded(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue)

        for fileUrl in allFileUrls {
            let taskHandle = execution(fileUrl)
            urlHandles.append((taskHandle, fileUrl))
        }

        return urlHandles
    }
    
    private func collectFileUrlsIfNeeded(with rootUrls: [URL], sourcesListFormatValue: String?) throws {
        guard allFileUrls.isEmpty else {
            return
        }
        
        let enumerator = FileEnumerator()
        
        for url in rootUrls {
            try enumerator.enumerate(from: url, withSourcesListFormat: sourcesListFormatValue) { (fileUrl: URL) in
                allFileUrls.append(fileUrl)
            }
        }
    }

    // MARK: - Extension Parsing

    /// Parse source files in directories specified by the given root URLs
    /// for component extension data models.
    ///
    /// - parameter rootUrls: The URLs of the directories to scan from.
    /// - parameter sourcesListFormatValue: The optional `String` value of
    /// the format used by the sources list file. If `nil` and the the given
    /// `rootUrl` is a file containing a list of Swift source paths, the
    /// `SourcesListFileFormat.newline` format is used. If the given `rootUrl`
    /// is not a file containing a list of Swift source paths, this value is
    /// ignored.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If a filename's suffix matches any in the this list,
    /// the file will not be parsed.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If a file's URL path contains any elements in this list, the file
    /// will not be parsed.
    /// - parameter parsedComponents: The components that are parsed out
    /// from declarations, whose extensions this method parses.
    /// - parameter executor: The executor to use for concurrent processing
    /// of files.
    /// - parameter timeout: The timeout value, in seconds, to use for
    /// waiting on parsing tasks.
    /// - returns: The list of component extensions for parsed components
    /// and their import statements.
    /// - throws: If any error occurred during execution.
    func parseAndCollectComponentExtensionDataModels(with rootUrls: [URL], sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], parsedComponents: [ASTComponent], using executor: SequenceExecutor, with timeout: TimeInterval) throws -> ([ASTComponentExtension], Set<String>) {
        let componentExtensionUrlHandles: [ComponentExtensionsUrlSequenceHandle] = try enqueueExtensionParsingTasks(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, parsedComponents: parsedComponents, using: executor)
        return try collectExtensionDataModels(with: componentExtensionUrlHandles, waitUpTo: timeout)
    }

    private func enqueueExtensionParsingTasks(with rootUrls: [URL], sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], parsedComponents: [ASTComponent], using executor: SequenceExecutor) throws -> [ComponentExtensionsUrlSequenceHandle] {
        return try executeAndCollectTaskHandles(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue) { (fileUrl: URL) -> SequenceExecutionHandle<ComponentExtensionNode> in
            let task = ComponentExtensionsFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths, components: parsedComponents)
            return executor.executeSequence(from: task) { (currentTask: Task, currentResult: Any) -> SequenceExecution<ComponentExtensionNode> in
                if currentTask is ComponentExtensionsFilterTask, let filterResult = currentResult as? FilterResult {
                    switch filterResult {
                    case .shouldProcess(let url, let content):
                        return .continueSequence(ASTProducerTask(sourceUrl: url, sourceContent: content))
                    case .skip:
                        return .endOfSequence(ComponentExtensionNode(extensions: [], imports: []))
                    }
                } else if currentTask is ASTProducerTask, let ast = currentResult as? AST {
                    return .continueSequence(ComponentExtensionsParserTask(ast: ast, components: parsedComponents))
                } else if currentTask is ComponentExtensionsParserTask, let node = currentResult as? ComponentExtensionNode {
                    return .endOfSequence(node)
                } else {
                    error("Unhandled task \(currentTask) with result \(currentResult)")
                }
            }
        }
    }

    private func collectExtensionDataModels(with urlHandles: [ComponentExtensionsUrlSequenceHandle], waitUpTo timeout: TimeInterval) throws -> ([ASTComponentExtension], Set<String>) {
        var extensions = [ASTComponentExtension]()
        var imports = Set<String>()
        for urlHandle in urlHandles {
            do {
                let node = try urlHandle.handle.await(withTimeout: timeout)
                extensions.append(contentsOf: node.extensions)
                // Ignore imports if we don't find anything useful in this file
                if !node.extensions.isEmpty {
                    for statement in node.imports {
                        imports.insert(statement)
                    }
                }
            } catch SequenceExecutionError.awaitTimeout(let taskId) {
                throw DependencyGraphParserError.timeout(urlHandle.fileUrl.absoluteString, taskId)
            } catch {
                throw error
            }
        }
        return (extensions, imports)
    }

    // MARK: - Component Initializer Parsing

    /// Collect all the source file contents that contain component
    /// instantiations from the given root URLs.
    ///
    /// - parameter rootUrls: The URLs of the directories to scan from.
    /// - parameter sourcesListFormatValue: The optional `String` value of
    /// the format used by the sources list file. If `nil` and the the given
    /// `rootUrl` is a file containing a list of Swift source paths, the
    /// `SourcesListFileFormat.newline` format is used. If the given `rootUrl`
    /// is not a file containing a list of Swift source paths, this value is
    /// ignored.
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If a filename's suffix matches any in the this list,
    /// the file will not be parsed.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If a file's URL path contains any elements in this list, the file
    /// will not be parsed.
    /// - parameter executor: The executor to use for concurrent processing
    /// of files.
    /// - parameter timeout: The timeout value, in seconds, to use for
    /// waiting on parsing tasks.
    /// - returns: The source file URL and content pairs.
    /// - throws: If any error occurred during execution.
    func sourceUrlContentsContainComponentInstantiations(with rootUrls: [URL], sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], using executor: SequenceExecutor, with timeout: TimeInterval) throws -> [UrlFileContent] {
        let initsUrlHandles = try enqueueComponentInitsTasks(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor)
        return try collectInitsDataModels(with: initsUrlHandles, waitUpTo: timeout)
    }

    private func enqueueComponentInitsTasks(with rootUrls: [URL], sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], using executor: SequenceExecutor) throws -> [ComponentInitsUrlSequenceHandle] {
        return try executeAndCollectTaskHandles(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue) { (fileUrl: URL) -> SequenceExecutionHandle<UrlFileContent?> in
            let task = ComponentInitsFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths)
            return executor.executeSequence(from: task) { (currentTask: Task, currentResult: Any) -> SequenceExecution<UrlFileContent?> in
                if currentTask is ComponentInitsFilterTask, let filterResult = currentResult as? FilterResult {
                    switch filterResult {
                    case .shouldProcess(let url, let content):
                        return .endOfSequence((url, content))
                    case .skip:
                        return .endOfSequence(nil)
                    }
                } else {
                    error("Unhandled task \(currentTask) with result \(currentResult)")
                }
            }
        }
    }

    private func collectInitsDataModels(with urlHandles: [ComponentInitsUrlSequenceHandle], waitUpTo timeout: TimeInterval) throws -> [UrlFileContent] {
        var sourceUrlContents = [UrlFileContent]()
        for urlHandle in urlHandles {
            do {
                let urlContent = try urlHandle.handle.await(withTimeout: timeout)
                if let urlContent = urlContent {
                    sourceUrlContents.append(urlContent)
                }
            } catch SequenceExecutionError.awaitTimeout(let taskId) {
                throw DependencyGraphParserError.timeout(urlHandle.fileUrl.absoluteString, taskId)
            } catch {
                throw error
            }
        }
        return sourceUrlContents
    }
}

private typealias ComponentExtensionsUrlSequenceHandle = (handle: SequenceExecutionHandle<ComponentExtensionNode>, fileUrl: URL)
private typealias ComponentInitsUrlSequenceHandle = (handle: SequenceExecutionHandle<UrlFileContent?>, fileUrl: URL)
