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

/// The entry utility for the parsing phase. The parser deeply scans a
/// directory and parses the relevant Swift source files, and finally
/// outputs the dependency graph.
class PluginizedDependencyGraphParser {

    /// Parse all the Swift sources within the directories of given URLs,
    /// excluding any file that contains a suffix specified in the given
    /// exclusion list. Parsing sources concurrently using the given executor.
    ///
    /// - parameter rootUrls: The URLs of the directories to scan from.
    /// - parameter exclusionSuffixes: If a file name contains a suffix
    /// in this list, the said file is excluded from parsing.
    /// - parameter executor: The executor to use for concurrent processing
    /// of files.
    /// - returns: The list of component data models, pluginized component
    /// data models and sorted import statements.
    /// - throws: `DependencyGraphParserError.timeout` if parsing a Swift
    /// source timed out.
    func parse(from rootUrls: [URL], excludingFilesWith exclusionSuffixes: [String] = [], using executor: SequenceExecutor) throws -> ([Component], [PluginizedComponent], [String]) {
        let urlHandles: [UrlSequenceHandle] = enqueueParsingTasks(with: rootUrls, excludingFilesWith: exclusionSuffixes, using: executor)
        let (pluginizedComponents, nonCoreComponents, pluginExtensions, components, dependencies, imports) = try collectDataModels(with: urlHandles)
        return process(pluginizedComponents, nonCoreComponents, pluginExtensions, components, dependencies, imports)
    }

    // MARK: - Private

    private func enqueueParsingTasks(with rootUrls: [URL], excludingFilesWith exclusionSuffixes: [String], using executor: SequenceExecutor) -> [(SequenceExecutionHandle<PluginizedDependencyGraphNode>, URL)] {
        var taskHandleTuples = [(handle: SequenceExecutionHandle<PluginizedDependencyGraphNode>, fileUrl: URL)]()

        // Enumerate all files and execute parsing sequences concurrently.
        let enumerator = FileEnumerator()
        for url in rootUrls {
            enumerator.enumerate(from: url) { (fileUrl: URL) in
                let task = PluginizedFileFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes)
                let taskHandle = executor.executeSequence(from: task, with: nextExecution(after:with:))
                taskHandleTuples.append((taskHandle, fileUrl))
            }
        }

        return taskHandleTuples
    }

    private func nextExecution(after currentTask: Task, with currentResult: Any) -> SequenceExecution<PluginizedDependencyGraphNode> {
        if currentTask is PluginizedFileFilterTask, let filterResult = currentResult as? FilterResult {
            switch filterResult {
            case .shouldParse(let url, let content):
                return .continueSequence(ASTProducerTask(sourceUrl: url, sourceContent: content))
            case .skip:
                return .endOfSequence(PluginizedDependencyGraphNode(pluginizedComponents: [], nonCoreComponents: [], pluginExtensions: [], components: [], dependencies: [], imports: []))
            }
        } else if currentTask is ASTProducerTask, let ast = currentResult as? AST {
            return .continueSequence(PluginizedASTParserTask(ast: ast))
        } else if currentTask is PluginizedASTParserTask, let node = currentResult as? PluginizedDependencyGraphNode {
            return .endOfSequence(node)
        } else {
            fatalError("Unhandled task \(currentTask) with result \(currentResult)")
        }
    }

    private func collectDataModels(with urlHandles: [UrlSequenceHandle]) throws -> ([PluginizedASTComponent], [ASTComponent], [PluginExtension], [ASTComponent], [Dependency], Set<String>) {
        var pluginizedComponents = [PluginizedASTComponent]()
        var nonCoreComponents = [ASTComponent]()
        var pluginExtensions = [PluginExtension]()
        var components = [ASTComponent]()
        var dependencies = [Dependency]()
        var imports = Set<String>()
        for urlHandle in urlHandles {
            do {
                let node = try urlHandle.handle.await(withTimeout: defaultTimeout)
                pluginizedComponents.append(contentsOf: node.pluginizedComponents)
                nonCoreComponents.append(contentsOf: node.nonCoreComponents)
                pluginExtensions.append(contentsOf: node.pluginExtensions)
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
        return (pluginizedComponents, nonCoreComponents, pluginExtensions, components, dependencies, imports)
    }

    private func process(_ pluginizedComponents: [PluginizedASTComponent], _ nonCoreComponents: [ASTComponent], _ pluginExtensions: [PluginExtension], _ components: [ASTComponent], _ dependencies: [Dependency], _ imports: Set<String>) -> ([Component], [PluginizedComponent], [String]) {
        var allComponents = nonCoreComponents + components
        let pluginizedComponentData = pluginizedComponents.map { (component: PluginizedASTComponent) -> ASTComponent in
            component.data
        }
        allComponents.append(contentsOf: pluginizedComponentData)
        let processors: [Processor] = [
            DuplicateValidator(components: allComponents, dependencies: dependencies),
            ParentLinker(components: allComponents),
            DependencyLinker(components: allComponents, dependencies: dependencies),
            NonCoreComponentLinker(pluginizedComponents: pluginizedComponents, nonCoreComponents: nonCoreComponents),
            PluginExtensionLinker(pluginizedComponents: pluginizedComponents, pluginExtensions: pluginExtensions)
        ]
        for processor in processors {
            do {
                try processor.process()
            } catch ProcessingError.fail(let message) {
                fatalError(message)
            } catch {
                fatalError("Unknown error: \(error)")
            }
        }

        // Return back non-core components as well since they can be treated as any regular component.
        let valueTypeComponents = (components + nonCoreComponents).map { (astComponent: ASTComponent) -> Component in
            astComponent.valueType
        }
        let valueTypePluginizedComponents = pluginizedComponents.map { (astComponent: PluginizedASTComponent) -> PluginizedComponent in
            return astComponent.valueType
        }
        let sortedImports = imports.sorted()
        return (valueTypeComponents, valueTypePluginizedComponents, sortedImports)
    }
}

private typealias UrlSequenceHandle = (handle: SequenceExecutionHandle<PluginizedDependencyGraphNode>, fileUrl: URL)
