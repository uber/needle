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

import Basic
import Foundation
import SourceKittenFramework

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

    /// Parse all the Swift sources within the directory of given URL,
    /// excluding any file that contains a suffix specified in the given
    /// exclusion list. Parsing sources concurrently using the given executor.
    ///
    /// - parameter rootUrl: The URL of the directory to scan from.
    /// - parameter exclusionSuffixes: If a file name contains a suffix
    /// in this list, the said file is excluded from parsing.
    /// - parameter executor: The executor to use for concurrent processing
    /// of files.
    /// - returns: The list of component data models.
    /// - throws: `DependencyGraphParserError.timeout` if parsing a Swift
    /// source timed out.
    func parse(from rootUrl: URL, excludingFilesWithSuffixes exclusionSuffixes: [String] = [], using executor: SequenceExecutor) throws -> (components: [Component], imports: [String]) {
        var taskHandleTuples = [(handle: SequenceExecutionHandle<DependencyGraphNode>, fileUrl: URL)]()

        // Enumerate all files and execute parsing sequences concurrently.
        let enumerator = newFileEnumerator(for: rootUrl)
        while let nextObjc = enumerator.nextObject() {
            if let fileUrl = nextObjc as? URL {
                let task = FileFilterTask(url: fileUrl, exclusionSuffixes: exclusionSuffixes)
                let taskHandle = executor.executeSequence(from: task) { (currentTask: Task, currentResult: Any) -> SequenceExecution<DependencyGraphNode> in
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
                taskHandleTuples.append((taskHandle, fileUrl))
            }
        }

        // Wait for all sequences to finish.
        var components = [ASTComponent]()
        var dependencies = [Dependency]()
        var imports = Set<String>()
        for tuple in taskHandleTuples {
            do {
                let node = try tuple.handle.await(withTimeout: 30)
                components.append(contentsOf: node.components)
                dependencies.append(contentsOf: node.dependencies)
                for statement in node.imports {
                    imports.insert(statement)
                }
            } catch SequenceExecutionError.awaitTimeout {
                throw DependencyGraphParserError.timeout(tuple.fileUrl.absoluteString)
            } catch {
                fatalError("Unhandled task execution error \(error)")
            }
        }

        validate(components, dependencies)
        linkParents(for: components)
        link(components, to: dependencies)

        let valueTypeComponents = components.map { (astComponent: ASTComponent) -> Component in
            astComponent.valueType
        }
        return (valueTypeComponents, imports.sorted())
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

    private func validate(_ components: [ASTComponent], _ dependencies: [Dependency]) {
        // Validate duplicates. If we want to support components/dependencies that have the
        // same name across modules, then this should be removed. One option to support such
        // scenario without trying to detect module structure is to simply use the file URL
        // of the component/dependency as a proxy for module.
        let duplicateValidator = DuplicateValidator()
        var result = duplicateValidator.validate(components)
        switch result {
        case .duplicate(let name):
            fatalError("Needle does not support components with the same name \(name)")
        default:
            break
        }

        result = duplicateValidator.validate(dependencies)
        switch result {
        case .duplicate(let name):
            fatalError("Needle does not support dependency protocols with the same name \(name)")
        default:
            break
        }
    }

    private func linkParents(for components: [ASTComponent]) {
        var nameToComponent = [String: ASTComponent]()
        for component in components {
            nameToComponent[component.name] = component
        }
        for component in components {
            for typeName in component.expressionCallTypeNames {
                if let childComponent = nameToComponent[typeName] {
                    childComponent.parents.append(component)
                }
            }
        }
    }

    private func link(_ components: [ASTComponent], to dependencies: [Dependency]) {
        var nameToDependency: [String: Dependency] = [emptyDependency.name: emptyDependency]
        for dependency in dependencies {
            nameToDependency[dependency.name] = dependency
        }
        for component in components {
            if let dependency = nameToDependency[component.dependencyProtocolName] {
                component.dependencyProtocol = dependency
            } else {
                fatalError("Missing dependency protocol data model for \(component.dependencyProtocolName).")
            }
        }
    }
}
