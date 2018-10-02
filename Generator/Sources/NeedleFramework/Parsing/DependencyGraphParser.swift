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
    /// Parsing a particular source file timed out.
    case timeout(String)
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
    /// - parameter exclusionSuffixes: The list of file name suffixes to
    /// check from. If a filename's suffix matches any in the this list,
    /// the file will not be parsed.
    /// - parameter exclusionPaths: The list of path components to check.
    /// If a file's URL path contains any elements in this list, the file
    /// will not be parsed.
    /// - parameter executor: The executor to use for concurrent processing
    /// of files.
    /// - returns: The list of component data models and sorted import
    /// statements.
    /// - throws: `DependencyGraphParserError.timeout` if parsing a Swift
    /// source timed out.
    func parse(from rootUrls: [URL], excludingFilesEndingWith exclusionSuffixes: [String] = [], excludingFilesWithPaths exclusionPaths: [String] = [], using executor: SequenceExecutor) throws -> (components: [Component], imports: [String]) {
        let urlHandles: [UrlSequenceHandle] = enqueueParsingTasks(with: rootUrls, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor)
        let (components, dependencies, imports) = try collectDataModels(with: urlHandles)
        return process(components, dependencies, imports)
    }

    // MARK: - Private

    private func enqueueParsingTasks(with rootUrls: [URL], excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], using executor: SequenceExecutor) -> [(SequenceExecutionHandle<DependencyGraphNode>, URL)] {
        var taskHandleTuples = [(handle: SequenceExecutionHandle<DependencyGraphNode>, fileUrl: URL)]()

        // Enumerate all files and execute parsing sequences concurrently.
        let enumerator = FileEnumerator()
        for url in rootUrls {
            enumerator.enumerate(from: url) { (fileUrl: URL) in
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
                return .endOfSequence(DependencyGraphNode(components: [], dependencies: [], imports: []))
            }
        } else if currentTask is ASTProducerTask, let ast = currentResult as? AST {
            return .continueSequence(ASTParserTask(ast: ast))
        } else if currentTask is ASTParserTask, let node = currentResult as? DependencyGraphNode {
            return .endOfSequence(node)
        } else {
            fatalError("Unhandled task \(currentTask) with result \(currentResult)")
        }
    }

    private func collectDataModels(with urlHandles: [UrlSequenceHandle]) throws -> ([ASTComponent], [Dependency], Set<String>) {
        var components = [ASTComponent]()
        var dependencies = [Dependency]()
        var imports = Set<String>()
        for urlHandle in urlHandles {
            do {
                let node = try urlHandle.handle.await(withTimeout: defaultTimeout)
                components.append(contentsOf: node.components)
                dependencies.append(contentsOf: node.dependencies)
                for statement in node.imports {
                    imports.insert(statement)
                }
            } catch SequenceExecutionError.awaitTimeout {
                throw DependencyGraphParserError.timeout(urlHandle.fileUrl.absoluteString)
            } catch {
                fatalError("Unhandled task execution error \(error)")
            }
        }
        return (components, dependencies, imports)
    }

    private func process(_ components: [ASTComponent], _ dependencies: [Dependency], _ imports: Set<String>) -> ([Component], [String]) {
        let processors: [Processor] = [
            DuplicateValidator(components: components, dependencies: dependencies),
            ParentLinker(components: components),
            DependencyLinker(components: components, dependencies: dependencies),
            CycleValidator(components: components)
        ]
        for processor in processors {
            do {
                try processor.process()
            } catch {
                fatalError("\(error)")
            }
        }

        let valueTypeComponents = components.map { (astComponent: ASTComponent) -> Component in
            astComponent.valueType
        }
        let sortedImports = imports.sorted()
        return (valueTypeComponents, sortedImports)
    }
}

private typealias UrlSequenceHandle = (handle: SequenceExecutionHandle<DependencyGraphNode>, fileUrl: URL)
