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

/// A task that parses Swift AST into dependency graph data models.
class ASTParserTask: AbstractTask<DependencyGraphNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    init(ast: AST) {
        self.ast = ast
        super.init(id: TaskIds.astParserTask.rawValue)
    }

    /// Execute the task and returns the dependency graph data model.
    ///
    /// - returns: Parsed `DependencyGraphNode`.
    override func execute() -> DependencyGraphNode {
        let (components, dependencies) = parseStructures()
        return DependencyGraphNode(components: components, dependencies: dependencies, imports: ast.imports)
    }

    // MARK: - Private

    private let ast: AST

    private func parseStructures() -> ([ASTComponent], [Dependency]) {
        var components = [ASTComponent]()
        var dependencies = [Dependency]()

        let substructures = ast.structure.substructures
        for item in substructures {
            if let substructure = item as? [String: SourceKitRepresentable] {
                if substructure.isComponent {
                    let dependencyProtocolName = substructure.dependencyProtocolName(for: "Component")
                    components.append(ASTComponent(name: substructure.name, dependencyProtocolName: dependencyProtocolName, properties: substructure.properties, expressionCallTypeNames: substructure.uniqueExpressionCallNames))
                } else if substructure.isDependencyProtocol {
                    dependencies.append(Dependency(name: substructure.name, properties: substructure.properties))
                }
            }
        }
        return (components, dependencies)
    }
}
