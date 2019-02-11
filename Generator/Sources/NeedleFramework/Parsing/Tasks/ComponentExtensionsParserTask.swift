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

        let substructures = ast.structure.substructures
        for substructure in substructures {
            if substructure.isExtension(of: componentNames) {
                let properties = try substructure.properties()
                extensions.append(ASTComponentExtension(name: substructure.name, properties: properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames))
            }
        }
        return ComponentExtensionNode(extensions: extensions, imports: ast.imports)
    }

    // MARK: - Private

    private let ast: AST
    private let componentNames: [String]
}

// MARK: - SourceKit AST Parsing Utilities

private extension Structure {

    /// Check if this structure represents a `Component` extension for
    /// a component with a name in the given list.
    ///
    /// - parameter componentNames: The list of component names to check.
    /// - returns: `true` if this structure is an extension. `false`
    /// otherwise.
    func isExtension(of componentNames: [String]) -> Bool {
        let type = dictionary["key.kind"] as! String
        if type == "source.lang.swift.decl.extension" {
            return componentNames.contains(self.name)
        }

        return false
    }
}
