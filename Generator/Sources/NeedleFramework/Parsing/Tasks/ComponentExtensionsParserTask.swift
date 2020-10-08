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
import SwiftSyntax
import SourceParsingFramework

/// A task that parses Swift AST component extensions into data models.
class ComponentExtensionsParserTask: AbstractTask<ComponentExtensionNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    /// - parameter components: All the parsed out components.
    init(ast: AST, components: [ASTComponent]) {
        self.ast = ast
        self.componentNames = components.map { (component: ASTComponent) -> String in
            component.name
        }
        super.init(id: TaskIds.componentExtenionsParserTask.rawValue)
    }

    /// Execute the task and returns the dependency graph data model.
    ///
    /// - returns: Parsed `DependencyGraphNode`.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> ComponentExtensionNode {
        var extensions = [ASTComponentExtension]()
        
        let visitor = Visitor(componentNames: componentNames)
        visitor.walk(ast.sourceFileSyntax)
        extensions = visitor.extensions
        
        return ComponentExtensionNode(extensions: extensions, imports: visitor.imports)
    }

    // MARK: - Private

    private let ast: AST
    private let componentNames: [String]
}

private final class Visitor: BaseVisitor {
    private(set) var extensions: [ASTComponentExtension] = []
    
    private let componentNames: [String]
    
    init(componentNames: [String]) {
        self.componentNames = componentNames
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.isExtension(of: componentNames) {
            currentEntityNode = node
            return .visitChildren
        } else {
            return .skipChildren
        }
    }
    
    override func visitPost(_ node: ExtensionDeclSyntax) {
        let extensionName = node.typeName
        if extensionName == currentEntityNode?.typeName {
            let componentExtension = ASTComponentExtension(name: extensionName,
                                                           properties: propertiesDict[extensionName, default: []],
                                                           expressionCallTypeNames: Array(componentToCallExprs[extensionName, default:[]]).sorted())
            extensions.append(componentExtension)
            propertiesDict[extensionName] = []
            componentToCallExprs[extensionName] = []
        }
    }
}
