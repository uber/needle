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
import SourceKittenFramework

/// The extended AST parser task that parses all components, dependency
/// protocols and import statements, including pluginized components.
class PluginizedASTParserTask: AbstractTask<PluginizedDependencyGraphNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    init(ast: AST) {
        self.ast = ast
        super.init(id: TaskIds.pluginizedASTParserTask.rawValue)
    }

    /// Execute the task and returns the dependency graph data model.
    ///
    /// - returns: Parsed `PluginizedDependencyGraphNode`.
    override func execute() -> PluginizedDependencyGraphNode {
        let baseTask = ASTParserTask(ast: ast)
        let baseNode = baseTask.execute()
        let (pluginizedComponents, nonCoreComponents, pluginExtensions) = parsePluginizedStructures()
        return PluginizedDependencyGraphNode(pluginizedComponents: pluginizedComponents, nonCoreComponents: nonCoreComponents, pluginExtensions: pluginExtensions, components: baseNode.components, dependencies: baseNode.dependencies, imports: baseNode.imports)
    }

    // MARK: - Private

    private let ast: AST

    private func parsePluginizedStructures() -> ([PluginizedASTComponent], [ASTComponent], [PluginExtension]) {
        var pluginizedComponents = [PluginizedASTComponent]()
        var nonCoreComponents = [ASTComponent]()
        var pluginExtensions = [PluginExtension]()

        let substructures = ast.structure.substructures
        for substructure in substructures {
            if substructure.isPluginizedComponent {
                let (dependencyProtocolName, pluginExtensionName, nonCoreComponentName) = substructure.pluginizedGenerics
                let component = ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, properties: substructure.properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames)
                pluginizedComponents.append(PluginizedASTComponent(data: component, pluginExtensionType: pluginExtensionName, nonCoreComponentType: nonCoreComponentName))
            } else if substructure.isNonCoreComponent {
                let dependencyProtocolName = substructure.dependencyProtocolName(for: "NonCoreComponent")
                let component = ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, properties: substructure.properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames)
                nonCoreComponents.append(component)
            } else if substructure.isPluginExtension {
                pluginExtensions.append(PluginExtension(name: substructure.name, properties: substructure.properties))
            }
        }

        return (pluginizedComponents, nonCoreComponents, pluginExtensions)
    }
}

// MARK: - SourceKit AST Parsing Utilities

extension Structure {
    var isPluginizedComponent: Bool {
        return dictionary.isPluginizedComponent
    }

    var isNonCoreComponent: Bool {
        return dictionary.isNonCoreComponent
    }

    var isPluginExtension: Bool {
        return dictionary.isPluginExtension
    }

    var pluginizedGenerics: (dependencyProtocolName: String, pluginExtensionName: String, nonCoreComponentName: String) {
        return dictionary.pluginizedGenerics
    }
}

private extension Dictionary where Key: ExpressibleByStringLiteral {

    var isPluginizedComponent: Bool {
        let regex = Regex("^(\(needleModuleName).)?PluginizedComponent *<(.+)>")
        return inheritedTypes.contains { (type: String) -> Bool in
            regex.firstMatch(in: type) != nil
        }
    }

    var isNonCoreComponent: Bool {
        let regex = Regex("^(\(needleModuleName).)?NonCoreComponent *<(.+)>")
        return inheritedTypes.contains { (type: String) -> Bool in
            regex.firstMatch(in: type) != nil
        }
    }

    var isPluginExtension: Bool {
        return inheritedTypes.contains("PluginExtension")
    }

    var pluginizedGenerics: (dependencyProtocolName: String, pluginExtensionName: String, nonCoreComponentName: String) {
        let regex = Regex("^(\(needleModuleName).)?PluginizedComponent *<")
        let genericsString = inheritedTypes
            .compactMap { (type: String) -> String? in
                if regex.firstMatch(in: type) != nil {
                    let prefixIndex = type.index { (char: Character) -> Bool in
                        char == "<"
                    }
                    if let prefixIndex = prefixIndex {
                        let startIndex = type.index(after: prefixIndex)
                        let endIndex = type.index { (char: Character) -> Bool in
                            char == ">"
                        }
                        if let endIndex = endIndex {
                            return String(type[startIndex ..< endIndex])
                        }
                    }
                }
                return nil
            }
            .first
        if let genericsString = genericsString {
            let generics = genericsString.split(separator: ",")
            if generics.count < 3 {
                fatalError("\(name) as a PluginizedComponent should have 3 generic types. Instead of \(genericsString)")
            }
            let dependencyProtocolName = generics[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let pluginExtensionName = generics[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let nonCoreComponentName = generics[2].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return (dependencyProtocolName, pluginExtensionName, nonCoreComponentName)
        } else {
            fatalError("\(name) is being parsed as a PluginizedComponent. Yet its generic types cannot be parsed. \(inheritedTypes)")
        }
        fatalError()
    }
}
