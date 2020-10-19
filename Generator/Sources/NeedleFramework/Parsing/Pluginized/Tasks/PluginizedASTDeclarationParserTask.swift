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
import SwiftSyntax

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
        let visitor = PluginizedVisitor(sourceHash: ast.sourceHash)
        visitor.walk(ast.sourceFileSyntax)
        let pluginizedComponents = visitor.pluginizedComponents
        let nonCoreComponents = visitor.nonCoreComponents
        let pluginExtensions = visitor.pluginExtensions
        
        return PluginizedDependencyGraphNode(pluginizedComponents: pluginizedComponents, nonCoreComponents: nonCoreComponents, pluginExtensions: pluginExtensions, components: baseNode.components, dependencies: baseNode.dependencies, imports:  baseNode.imports + visitor.imports)
    }

    // MARK: - Private

    private let ast: AST
}

private final class PluginizedVisitor: BaseVisitor {
    private(set) var pluginExtensions: [PluginExtension] = []
    private(set) var pluginizedComponents: [PluginizedASTComponent] = []
    private(set) var nonCoreComponents: [ASTComponent] = []
    
    private var currentPluginizedComponentName: String = ""
    private var currentNonCoreComponentName: String = ""
    private var currentPluginExtensionGenerics: (dependencyProtocolName: String, pluginExtensionName: String, nonCoreComponentName: String) = ("", "", "")
    
    private let sourceHash: String
    
    init(sourceHash: String) {
        self.sourceHash = sourceHash
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.isPluginExtension {
            currentEntityNode = node
            return .visitChildren
        } else {
            return .skipChildren
        }
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        let protocolName = node.typeName
        if protocolName == currentEntityNode?.typeName {
            let pluginExtension = PluginExtension(name: protocolName,
                                                  properties: propertiesDict[protocolName, default: []])
            pluginExtensions.append(pluginExtension)
        }
    }
    
    override func visit(_ node: ClassDeclSyntax) ->SyntaxVisitorContinueKind {
        if node.isPluginizedComponent {
            isParsingComponentDeclarationLine = true
            currentEntityNode = node
            currentPluginizedComponentName = node.typeName
            return .visitChildren
        } else if node.isNonCoreComponent {
            isParsingComponentDeclarationLine = true
            currentEntityNode = node
            currentNonCoreComponentName = node.typeName
            return .visitChildren
        } else {
            return .skipChildren
        }
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        let componentName = node.typeName
        if componentName == currentPluginizedComponentName {
            let component = ASTComponent(name: componentName,
                                         dependencyProtocolName: currentPluginExtensionGenerics.dependencyProtocolName,
                                         isRoot: node.isRoot,
                                         sourceHash: sourceHash,
                                         properties: propertiesDict[componentName, default: []],
                                         expressionCallTypeNames: Array(componentToCallExprs[componentName, default: []]).sorted())
            let pluginizedComponent = PluginizedASTComponent(data: component,
                                                             pluginExtensionType: currentPluginExtensionGenerics.pluginExtensionName,
                                                             nonCoreComponentType: currentPluginExtensionGenerics.nonCoreComponentName)
            pluginizedComponents.append(pluginizedComponent)
        } else if componentName == currentNonCoreComponentName {
            let component = ASTComponent(name: componentName,
                                         dependencyProtocolName: currentDependencyProtocol ?? "",
                                         isRoot: false,
                                         sourceHash: sourceHash,
                                         properties: propertiesDict[componentName, default: []],
                                         expressionCallTypeNames: Array(componentToCallExprs[componentName, default: []]).sorted())
            nonCoreComponents.append(component)
        }
    }
    
    override func visitPost(_ node: GenericArgumentListSyntax) {
        guard isParsingComponentDeclarationLine else { return }
        if currentEntityNode?.typeName == currentPluginizedComponentName {
            
            for (i, genericArgument) in node.enumerated() {
                let argumentName = genericArgument.argumentType.description.trimmed.removingModulePrefix
                
                switch i {
                case 0:
                    currentPluginExtensionGenerics.dependencyProtocolName = argumentName
                case 1:
                    currentPluginExtensionGenerics.pluginExtensionName = argumentName
                case 2:
                    currentPluginExtensionGenerics.nonCoreComponentName = argumentName
                default:
                    warning("Found more generic arguments than expected in \(currentEntityNode?.typeName ?? "UNKNOWN")")
                }
            }
        } else if currentEntityNode?.typeName == currentNonCoreComponentName {
            currentDependencyProtocol = node.first?.argumentType.description.trimmed.removingModulePrefix
        }
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
}
