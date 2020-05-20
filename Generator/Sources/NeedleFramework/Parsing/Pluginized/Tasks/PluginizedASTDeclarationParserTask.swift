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
import SourceParsingFramework

/// The extended AST parser task that parses all components, dependency
/// protocols declarations and import statements, including pluginized
/// components.
class PluginizedDeclarationsParserTask: AbstractTask<PluginizedDependencyGraphNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    init(ast: AST) {
        self.ast = ast
        super.init(id: TaskIds.pluginizedDeclarationsParserTask.rawValue)
    }

    /// Execute the task and returns the dependency graph data model.
    ///
    /// - returns: Parsed `PluginizedDependencyGraphNode`.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> PluginizedDependencyGraphNode {
        let baseTask = DeclarationsParserTask(ast: ast)
        let baseNode = try baseTask.execute()
        let (pluginizedComponents, nonCoreComponents, pluginExtensions) = try parsePluginizedStructures()
        return PluginizedDependencyGraphNode(pluginizedComponents: pluginizedComponents, nonCoreComponents: nonCoreComponents, pluginExtensions: pluginExtensions, components: baseNode.components, dependencies: baseNode.dependencies, imports: baseNode.imports)
    }

    // MARK: - Private

    private let ast: AST

    private func parsePluginizedStructures() throws -> ([PluginizedASTComponent], [ASTComponent], [PluginExtension]) {
        var pluginizedComponents = [PluginizedASTComponent]()
        var nonCoreComponents = [ASTComponent]()
        var pluginExtensions = [PluginExtension]()

        let substructures = ast.structure.substructures
        for substructure in substructures {
            if substructure.isPluginizedComponent {
                let (dependencyProtocolName, pluginExtensionName, nonCoreComponentName) = try substructure.pluginizedGenerics()
                let properties = try substructure.properties()
                // Pluginized components are never root.
                let component = ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, isRoot: false, properties: properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames)
                pluginizedComponents.append(PluginizedASTComponent(data: component, pluginExtensionType: pluginExtensionName, nonCoreComponentType: nonCoreComponentName))
            } else if substructure.isNonCoreComponent {
                let dependencyProtocolName = try substructure.dependencyProtocolName(for: "NonCoreComponent")
                let properties = try substructure.properties()
                // Non-core components are never root.
                let component = ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, isRoot: false, properties: properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames)
                nonCoreComponents.append(component)
            } else if substructure.isPluginExtension {
                let properties = try substructure.properties()
                pluginExtensions.append(PluginExtension(name: substructure.name, properties: properties))
            }
        }

        return (pluginizedComponents, nonCoreComponents, pluginExtensions)
    }
}

// MARK: - SourceKit AST Parsing Utilities

private extension Structure {

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

    func pluginizedGenerics() throws -> (dependencyProtocolName: String, pluginExtensionName: String, nonCoreComponentName: String) {
        let regex = Regex("^(\(needleModuleName).)?PluginizedComponent *<")
        let genericsString = inheritedTypes
            .compactMap { (type: String) -> String? in
                if regex.firstMatch(in: type) != nil {
                    let prefixIndex = type.firstIndex { (char: Character) -> Bool in
                        char == "<"
                    }
                    if let prefixIndex = prefixIndex {
                        let startIndex = type.index(after: prefixIndex)
                        let endIndex = type.firstIndex { (char: Character) -> Bool in
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
                throw GenericError.withMessage("\(name) as a PluginizedComponent should have 3 generic types. Instead of \(genericsString)")
            }
            let dependencyProtocolName = String(generics[0])
            let pluginExtensionName = String(generics[1])
            let nonCoreComponentName = String(generics[2])
            return (dependencyProtocolName, pluginExtensionName, nonCoreComponentName)
        } else {
            throw GenericError.withMessage("\(name) is being parsed as a PluginizedComponent. Yet its generic types cannot be parsed. \(inheritedTypes)")
        }
    }
}
