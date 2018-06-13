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

/// A task that parses Swift AST into dependency graph data models.
class ASTParserTask: AbstractTask<DependencyGraphNode> {

    /// Initializer.
    ///
    /// - parameter ast: The AST of the file to parse.
    init(ast: AST) {
        self.ast = ast
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
                    components.append(ASTComponent(name: substructure.name, dependencyProtocolName: substructure.dependencyProtocolName, properties: substructure.properties, expressionCallTypeNames: substructure.expressionCallNames))
                } else if substructure.isDependencyProtocol {
                    dependencies.append(Dependency(name: substructure.name, properties: substructure.properties))
                }
            }
        }
        return (components, dependencies)
    }
}

// MARK: - SourceKit AST Parsing Utilities

private extension Structure {

    var substructures: [SourceKitRepresentable] {
        return (dictionary["key.substructure"]  as? [SourceKitRepresentable]) ?? []
    }
}

private extension Dictionary where Key: ExpressibleByStringLiteral {

    var isComponent: Bool {
        let regex = Regex("Component *<(.+)>")
        return inheritedTypes.contains { (type: String) -> Bool in
            regex.firstMatch(in: type) != nil
        }
    }

    var isDependencyProtocol: Bool {
        return inheritedTypes.contains("Dependency")
    }

    var name: String {
        // A type must have a name.
        return self["key.name"] as! String
    }

    var dependencyProtocolName: String {
        let regex = Regex("Component *<")
        let result = inheritedTypes
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
        if let result = result {
            return result
        } else {
            fatalError("\(name) is being parsed as a Component. Yet its generic dependency type cannot be parsed.")
        }
    }

    var properties: [Property] {
        return filterSubstructure(by: "source.lang.swift.decl.var.instance")
            .filter { (item: [String: SourceKitRepresentable]) -> Bool in
                if let accessibility = item["key.accessibility"] as? String {
                    return accessibility != "source.lang.swift.accessibility.private" && accessibility != "source.lang.swift.accessibility.fileprivate"
                }
                fatalError("Property missing accessibility identifier.")
            }
            .map { (item: [String: SourceKitRepresentable]) -> Property in
                if let variableName = item["key.name"] as? String {
                    if let typeName = item["key.typename"] as? String {
                        return Property(name: variableName, type: typeName)
                    } else {
                        fatalError("Missing explicit type annotation for property \"\(variableName)\" in \(self.name)")
                    }
                }
                fatalError("Property \(item) does not have a name.")
            }
    }

    var expressionCallNames: [String] {
        return filterSubstructure(by: "source.lang.swift.expr.call", recursively: true)
            .map { (item: [String: SourceKitRepresentable]) -> String in
                item.name
            }
    }

    private var inheritedTypes: [String] {
        let types = self["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return types.compactMap { (item: SourceKitRepresentable) -> String? in
            (item as? [String: String])?["key.name"]
        }
    }

    private func filterSubstructure(by kind: String, recursively: Bool = false) -> [[String: SourceKitRepresentable]] {
        let subsctructures = self["key.substructure"] as? [[String: SourceKitRepresentable]] ?? []
        let currentLevelSubstructures = subsctructures.compactMap { (itemMap: [String: SourceKitRepresentable]) -> [String: SourceKitRepresentable]? in
            if itemMap["key.kind"] as? String == kind {
                return itemMap
            }
            return nil
        }
        if recursively && !subsctructures.isEmpty {
            return currentLevelSubstructures + subsctructures.flatMap { (substructure: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] in
                substructure.filterSubstructure(by: kind, recursively: recursively)
            }
        } else {
            return currentLevelSubstructures
        }
    }
}
