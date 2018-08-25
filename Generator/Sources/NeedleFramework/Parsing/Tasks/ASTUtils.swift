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

/// Extension of SourceKitten `Structure` to provide easy access to AST
/// properties.
extension Structure {

    /// The substructures of this structure.
    var substructures: [SourceKitRepresentable] {
        return (dictionary["key.substructure"]  as? [SourceKitRepresentable]) ?? []
    }
}

/// Extension of `Dictionary` to provide easy access to AST properties.
extension Dictionary where Key: ExpressibleByStringLiteral {

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

    /// The type name of this structure.
    var name: String {
        // A type must have a name.
        return self["key.name"] as! String
    }

    /// Parse the dependency protocol's type name for the component with
    /// given type name.
    ///
    /// - parameter componentType: The type name of the component.
    /// - returns: The dependency protocol type name.
    func dependencyProtocolName(for componentType: String) -> String {
        let regex = Regex("^(\(needleModuleName).)?\(componentType) *<")
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
            if result.contains(".") {
                // Contains a module name, strip this out
                return result.components(separatedBy: ".").last ?? result
            }
            return result
        } else {
            fatalError("\(name) is being parsed as a Component. Yet its generic dependency type cannot be parsed. \(inheritedTypes)")
        }
    }

    /// The properties of this structure.
    var properties: [Property] {
        return filterSubstructure(by: "source.lang.swift.decl.var.instance")
            .map { (item: [String: SourceKitRepresentable]) -> (Property, [String: SourceKitRepresentable]) in
                if let variableName = item["key.name"] as? String {
                    if let typeName = item["key.typename"] as? String {
                        return (Property(name: variableName, type: typeName), item)
                    } else {
                        fatalError("Missing explicit type annotation for property \"\(variableName)\" in \(self.name)")
                    }
                }
                fatalError("Property \(item) does not have a name.")
            }
            .compactMap { (propertyItem: (property: Property, item: [String: SourceKitRepresentable])) -> Property? in
                if let accessibility = propertyItem.item["key.accessibility"] as? String {
                    let isPrivate = (accessibility == "source.lang.swift.accessibility.private")
                    let isFilePrivate = (accessibility == "source.lang.swift.accessibility.fileprivate")
                    if isPrivate || isFilePrivate {
                        warning("\(self.name) (\(propertyItem.property.name): \(propertyItem.property.type)) property is \(isPrivate ? "private" : "fileprivate"), therefore inaccessible on DI graph.")
                        return nil
                    } else {
                        return propertyItem.property
                    }
                }
                fatalError("Property missing accessibility identifier.")
            }
    }

    /// The unique set of expression call types in this structure.
    var uniqueExpressionCallNames: [String] {
        let allNames = filterSubstructure(by: "source.lang.swift.expr.call", recursively: true)
            .map { (item: [String: SourceKitRepresentable]) -> String in
                item.name
            }
        let set = Set<String>(allNames)
        return Array(set).sorted()
    }

    /// The name of the inherited types of this structure.
    var inheritedTypes: [String] {
        let types = self["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return types.compactMap { (item: SourceKitRepresentable) -> String? in
            (item as? [String: String])?["key.name"]
        }
    }

    // MARK: - Private

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
