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
        let (components, dependencies) = try parseStructures()
        return DependencyGraphNode(components: components, dependencies: dependencies, imports: ast.imports)
    }

    // MARK: - Private

    private let ast: AST

    private func parseStructures() throws -> ([ASTComponent], [Dependency]) {
        var components = [ASTComponent]()
        var dependencies = [Dependency]()

        let substructures = ast.structure.substructures
        for substructure in substructures {
            if substructure.isComponent {
                let dependencyProtocolName = try substructure.dependencyProtocolName(for: "Component")
                let properties = try substructure.properties()
                components.append(ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, properties: properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames))
            } else if substructure.isDependencyProtocol {
                let properties = try substructure.properties()
                dependencies.append(Dependency(name: substructure.name, properties: properties))
            }
        }
        return (components, dependencies)
    }
}

// MARK: - SourceKit AST Parsing Utilities

private extension Structure {

    /// Check if this structure represents a `Component` subclass.
    var isComponent: Bool {
        let regex = Regex("^(\(needleModuleName).)?Component *<(.+)>")
        return inheritedTypes.contains { (type: String) -> Bool in
            regex.firstMatch(in: type) != nil
        }
    }

    /// Check if this structure represents a `Dependency` protocol.
    var isDependencyProtocol: Bool {
        return inheritedTypes.contains("Dependency") || inheritedTypes.contains("\(needleModuleName).Dependency")
    }
}
