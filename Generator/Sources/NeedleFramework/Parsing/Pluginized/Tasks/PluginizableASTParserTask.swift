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
import SourceKittenFramework

/// The extended AST parser task that parses all components, dependency
/// protocols and import statements, including pluginized components.
class PluginizableASTParserTask: AbstractTask<PluginizableDependencyGraphNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    init(ast: AST) {
        self.ast = ast
    }

    /// Execute the task and returns the dependency graph data model.
    ///
    /// - returns: Parsed `PluginizedDependencyGraphNode`.
    override func execute() -> PluginizableDependencyGraphNode {
        let baseTask = ASTParserTask(ast: ast)
        let baseNode = baseTask.execute()
        let extendedBaseComponents = baseNode.components
            .map { (component: ASTComponent) -> PluginizableASTComponent in
                return PluginizableASTComponent(data: component)
            }
        let (pluginizedComponents, nonCoreComponents) = parsePluginizedStructures()
        let allComponents = extendedBaseComponents + pluginizedComponents + nonCoreComponents

        return PluginizableDependencyGraphNode(components: allComponents, dependencies: baseNode.dependencies, imports: baseNode.imports)
    }

    // MARK: - Private

    private let ast: AST

    private func parsePluginizedStructures() -> ([PluginizableASTComponent], [PluginizableASTComponent]) {
        var pluginizedComponents = [PluginizableASTComponent]()
        var nonCoreComponents = [PluginizableASTComponent]()

        let substructures = ast.structure.substructures
        for item in substructures {
            if let substructure = item as? [String: SourceKitRepresentable] {
                if substructure.isPluginizedComponent {
                    let (dependencyProtocolName, pluginExtensionName, nonCoreComponentName) = substructure.pluginizedGenerics
                    let component = ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, properties: substructure.properties, expressionCallTypeNames: substructure.expressionCallNames)
                    pluginizedComponents.append(PluginizableASTComponent(data: component, pluginExtensionType: pluginExtensionName, nonCoreComponentType: nonCoreComponentName))
                } else if substructure.isNonCoreComponent {
                    let dependencyProtocolName = substructure.dependencyProtocolName(for: "NonCoreComponent")
                    let component = ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, properties: substructure.properties, expressionCallTypeNames: substructure.expressionCallNames)
                    nonCoreComponents.append(PluginizableASTComponent(data: component))
                }
            }
        }

        return (pluginizedComponents, nonCoreComponents)
    }
}

// MARK: - SourceKit AST Parsing Utilities

private extension Dictionary where Key: ExpressibleByStringLiteral {

    var isPluginizedComponent: Bool {
        let regex = Regex("^PluginizedComponent *<(.+)>")
        return inheritedTypes.contains { (type: String) -> Bool in
            regex.firstMatch(in: type) != nil
        }
    }

    var isNonCoreComponent: Bool {
        let regex = Regex("^NonCoreComponent *<(.+)>")
        return inheritedTypes.contains { (type: String) -> Bool in
            regex.firstMatch(in: type) != nil
        }
    }

    var pluginizedGenerics: (dependencyProtocolName: String, pluginExtensionName: String, nonCoreComponentName: String) {
        let regex = Regex("^PluginizedComponent *<")
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
