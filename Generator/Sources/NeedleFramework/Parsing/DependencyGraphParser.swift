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

/// The entry utility for the parsing phase. The parser deeply scans a
/// directory and parses the relevant Swift source files, and finally
/// outputs the dependency graph.
class DependencyGraphParser: AbstractDependencyGraphParser {

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
    func parse(from rootUrls: [URL], withSourcesListFormat sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String] = [], excludingFilesWithPaths exclusionPaths: [String] = [], using executor: SequenceExecutor, withTimeout timeout: TimeInterval) throws -> (components: [Component], imports: [String]) {
        // Collect data models for component and dependency declarations.
        let dependencyNodeUrlHandles: [DependencyNodeUrlSequenceHandle] = try enqueueDeclarationParsingTasks(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor)
        let (components, dependencies, imports) = try collectDeclarationDataModels(with: dependencyNodeUrlHandles, waitUpTo: timeout)

        // Collect data models for component extensions.
        let (componentExtensions, extensionImports) = try parseAndCollectComponentExtensionDataModels(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, parsedComponents: components, using: executor, with: timeout)
        let allImports = imports.union(extensionImports)

        // Collect source contents that contain component instantiations for validation.
        let initsSourceUrlContents = try sourceUrlContentsContainComponentInstantiations(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue, excludingFilesEndingWith: exclusionSuffixes, excludingFilesWithPaths: exclusionPaths, using: executor, with: timeout)

        // Process all the data models.
        return try process(components, with: componentExtensions, dependencies, allImports, validate: initsSourceUrlContents, using: executor, with: timeout)
    }

    // MARK: - Declaration Parsing

    private func enqueueDeclarationParsingTasks(with rootUrls: [URL], sourcesListFormatValue: String?, excludingFilesEndingWith exclusionSuffixes: [String], excludingFilesWithPaths exclusionPaths: [String], using executor: SequenceExecutor) throws -> [DependencyNodeUrlSequenceHandle] {
        return try executeAndCollectTaskHandles(with: rootUrls, sourcesListFormatValue: sourcesListFormatValue) { (fileUrl: URL) -> SequenceExecutionHandle<DependencyGraphNode> in
            let task = DeclarationsFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes, exclusionPaths: exclusionPaths)
            return executor.executeSequence(from: task, with: declarationNextExecution(after:with:))
        }
    }

    private func declarationNextExecution(after currentTask: Task, with currentResult: Any) -> SequenceExecution<DependencyGraphNode> {
        if currentTask is DeclarationsFilterTask, let filterResult = currentResult as? FilterResult {
            switch filterResult {
            case .shouldProcess(let url, let content):
                return .continueSequence(ASTProducerTask(sourceUrl: url, sourceContent: content))
            case .skip:
                return .endOfSequence(DependencyGraphNode(components: [], dependencies: [], imports: []))
            }
        } else if currentTask is ASTProducerTask, let ast = currentResult as? AST {
            return .continueSequence(DeclarationsParserTask(ast: ast))
        } else if currentTask is DeclarationsParserTask, let node = currentResult as? DependencyGraphNode {
            return .endOfSequence(node)
        } else {
            error("Unhandled task \(currentTask) with result \(currentResult)")
        }
    }

    private func collectDeclarationDataModels(with urlHandles: [DependencyNodeUrlSequenceHandle], waitUpTo timeout: TimeInterval) throws -> ([ASTComponent], [Dependency], Set<String>) {
        var components = [ASTComponent]()
        var dependencies = [Dependency]()
        var imports = Set<String>()
        for urlHandle in urlHandles {
            do {
                let node = try urlHandle.handle.await(withTimeout: timeout)
                components.append(contentsOf: node.components)
                dependencies.append(contentsOf: node.dependencies)
                for statement in node.imports {
                    imports.insert(statement)
                }
            } catch SequenceExecutionError.awaitTimeout(let taskId) {
                throw DependencyGraphParserError.timeout(urlHandle.fileUrl.absoluteString, taskId)
            } catch {
                throw error
            }
        }
        return (components, dependencies, imports)
    }

    // MARK: - Processing

    private func process(_ components: [ASTComponent], with componentExtensions: [ASTComponentExtension], _ dependencies: [Dependency], _ imports: Set<String>, validate initsSourceUrlContents: [UrlFileContent], using executor: SequenceExecutor, with timeout: TimeInterval) throws -> ([Component], [String]) {
        let processors: [Processor] = [
            DuplicateValidator(components: components, dependencies: dependencies),
            ComponentConsolidator(components: components, componentExtensions: componentExtensions),
            ParentLinker(components: components),
            DependencyLinker(components: components, dependencies: dependencies),
            AncestorCycleValidator(components: components),
            ComponentInstantiationValidator(components: components, urlFileContents: initsSourceUrlContents, executor: executor, timeout: timeout)
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

private typealias DependencyNodeUrlSequenceHandle = (handle: SequenceExecutionHandle<DependencyGraphNode>, fileUrl: URL)
