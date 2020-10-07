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

/// A task that parses Swift AST component and dependency declarations
/// into dependency graph data models.
class DeclarationsParserTask: AbstractTask<DependencyGraphNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    init(ast: AST) {
        self.ast = ast
        super.init(id: TaskIds.declarationsParserTask.rawValue)
    }

    /// Execute the task and returns the dependency graph data model.
    ///
    /// - returns: Parsed `DependencyGraphNode`.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> DependencyGraphNode {
        let (components, dependencies, imports) = try parseSyntax()
        return DependencyGraphNode(components: components, dependencies: dependencies, imports: imports)
    }

    // MARK: - Private

    private let ast: AST
    
    private func parseSyntax() throws -> ([ASTComponent], [Dependency], [String]) {
        let visitor = Visitor(sourceHash: ast.sourceHash)
        visitor.walk(ast.sourceFileSyntax)
        return (visitor.components, visitor.dependencies, visitor.imports)
    }
}

// MARK: - SyntaxVisitor

private final class Visitor: BaseVisitor {
    private(set) var dependencies: [Dependency] = []
    private(set) var components: [ASTComponent] = []
    
    private let sourceHash: String
    
    init(sourceHash: String) {
        self.sourceHash = sourceHash
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.isDependency {
            currentEntityNode = node
            return .visitChildren
        } else {
            return .skipChildren
        }
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        let protocolName = node.typeName
        if protocolName == currentEntityNode?.typeName {
            let dependency = Dependency(name: protocolName,
                                        properties: propertiesDict[protocolName, default: []],
                                        sourceHash: sourceHash)
            dependencies.append(dependency)
        }
    }
    
    override func visit(_ node: ClassDeclSyntax) ->SyntaxVisitorContinueKind {
        if node.isComponent {
            isParsingComponentDeclarationLine = true
            currentEntityNode = node
            return .visitChildren
        } else {
            return .skipChildren
        }
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        let componentName = node.typeName
        if componentName == currentEntityNode?.typeName {
            let dependencyProtocolName = node.isRoot ? emptyDependency.name : (currentDependencyProtocol ?? "")
            
            let component = ASTComponent(name: componentName,
                                         dependencyProtocolName: dependencyProtocolName,
                                         isRoot: node.isRoot,
                                         sourceHash: sourceHash,
                                         properties: propertiesDict[componentName, default: []],
                                         expressionCallTypeNames: Array(componentToCallExprs[componentName, default: []]).sorted())
            components.append(component)
        }
    }
    
    override func visitPost(_ node: GenericArgumentListSyntax) {
        guard isParsingComponentDeclarationLine else {return }
        currentDependencyProtocol = node.first?.argumentType.description.trimmed.removingModulePrefix
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
}
