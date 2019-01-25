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

/// Errors that can occur during parsing of the dependency graph from
/// Swift sources.
enum DependencyGraphParserError: Error {
    /// Parsing a particular source file timed out. The associated values
    /// are the path of the file being parsed and the ID of the task that
    /// was being executed when the timeout occurred.
    case timeout(String, Int)
}

/// The entry utility for the parsing phase. The parser deeply scans a
/// directory and parses the relevant Swift source files, and finally
/// outputs the dependency graph.
class DependencyGraphParser {

    /// Parse all the Swift sources within the directories of given URLs,
    /// excluding any file that contains a suffix specified in the given
    /// exclusion list. Parsing sources concurrently using the given executor.
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
    /// - returns: The list of component data models and sorted import
    /// statements.
    /// - throws: `DependencyGraphParserError.timeout` if parsing a Swift
    /// source timed out.
    func parse(from rootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String] = [], excludingFilesWithPaths exclusionPaths: [String] = [], using executor: SequenceExecutor, withTimeout timeout: Double) throws -> (components: [Component], imports: [String]) {
        let urlHandles: [UrlSequenceHandle] = try enqueueParsingTasks(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor)
        let (components, dependencies, imports, sourceContents) = try collectDataModels(with: urlHandles, waitUpTo: timeout)
        return try process(components, dependencies, imports, sourceContents)
    }

    // MARK: - Private

    private func enqueueParsingTasks(with rootUrls: [URL], sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], using executor: SequenceExecutor) throws -> [(SequenceExecutionHandle<DependencyGraphNode>, URL)] {
        var taskHandleTuples = [(handle: SequenceExecutionHandle<DependencyGraphNode>, fileUrl: URL)]()

        // Enumerate all files and execute parsing sequences concurrently.
        let enumerator = FileEnumerator()
        for url in rootUrls {
            try enumerator.enumerate(from: url, withSourcesListFormat: sourcesListFormatValue) { (fileUrl: URL) in
                let task = FileFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths)
                let taskHandle = executor.executeSequence(from: task, with: nextExecution(after:with:))
                taskHandleTuples.append((taskHandle, fileUrl))
            }
        }

        return taskHandleTuples
    }

    private func nextExecution(after currentTask: Task, with currentResult: Any) -> SequenceExecution<DependencyGraphNode> {
        if currentTask is FileFilterTask, let filterResult = currentResult as? FilterResult {
            switch filterResult {
            case .shouldParse(let url, let content):
                return .continueSequence(ASTProducerTask(sourceUrl: url, sourceContent: content))
            case .skip:
                return .endOfSequence(DependencyGraphNode(components: [], dependencies: [], imports: [], sourceContent: ""))
            }
        } else if currentTask is ASTProducerTask, let ast = currentResult as? AST {
            return .continueSequence(ASTParserTask(ast: ast))
        } else if currentTask is ASTParserTask, let node = currentResult as? DependencyGraphNode {
            return .endOfSequence(node)
        } else {
            fatalError("Unhandled task \(currentTask) with result \(currentResult)")
        }
    }

    private func collectDataModels(with urlHandles: [UrlSequenceHandle], waitUpTo timeout: Double) throws -> ([ASTComponent], [Dependency], Set<String>, [String]) {
        var components = [ASTComponent]()
        var dependencies = [Dependency]()
        var imports = Set<String>()
        var sourceContents = [String]()
        for urlHandle in urlHandles {
            do {
                let node = try urlHandle.handle.await(withTimeout: timeout)
                components.append(contentsOf: node.components)
                dependencies.append(contentsOf: node.dependencies)
                for statement in node.imports {
                    imports.insert(statement)
                }
                sourceContents.append(node.sourceContent)
            } catch SequenceExecutionError.awaitTimeout(let taskId) {
                throw DependencyGraphParserError.timeout(urlHandle.fileUrl.absoluteString, taskId)
            } catch {
                throw error
            }
        }
        return (components, dependencies, imports, sourceContents)
    }

    private func process(_ components: [ASTComponent], _ dependencies: [Dependency], _ imports: Set<String>, _ sourceContents: [String]) throws -> ([Component], [String]) {
        let processors: [Processor] = [
            DuplicateValidator(components: components, dependencies: dependencies),
            ParentLinker(components: components),
            DependencyLinker(components: components, dependencies: dependencies),
            AncestorCycleValidator(components: components),
            ComponentInstantiationValidator(components: components, fileContents: sourceContents)
        ]
        for processor in processors {
            try processor.process()
        }

        let valueTypeComponents = components.map { (astComponent: ASTComponent) -> Component in
            astComponent.valueType
        }
        let sortedImports = imports.sorted()
        return (valueTypeComponents, sortedImports)
    }
}

private typealias UrlSequenceHandle = (handle: SequenceExecutionHandle<DependencyGraphNode>, fileUrl: URL)
