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

/// Extension of SourceKitten `Structure` to provide easy access to a set
/// of common AST properties.
extension Structure {

    /// The substructures of this structure.
    var substructures: [Structure] {
        let substructures = (dictionary["key.substructure"]  as? [SourceKitRepresentable]) ?? []

        let result = substructures.compactMap { (substructure: SourceKitRepresentable) -> Structure? in
            if let structure = substructure as? [String: SourceKitRepresentable] {
                return Structure(sourceKitResponse: structure)
            } else {
                return nil
            }
        }
        return result
    }

    /// The type name of this structure.
    var name: String {
        /// The type name of this structure.
        return dictionary["key.name"] as! String
    }

    /// Parse the dependency protocol's type name for the component with
    /// given type name.
    ///
    /// - parameter componentType: The type name of the component.
    /// - returns: The dependency protocol type name.
    /// - throws: 'GeneratorError` if parsing dependency protocol name from
    /// generics failed.
    func dependencyProtocolName(for componentType: String) throws -> String {
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
            throw GeneratorError.withMessage("\(name) is being parsed as a Component. Yet its generic dependency type cannot be parsed. \(inheritedTypes)")
        }
    }

    /// The properties of this structure.
    ///
    /// - throws: `GeneratorError` if parsing properties failed.
    func properties() throws -> [Property] {
        return try filterSubstructure(by: "source.lang.swift.decl.var.instance")
            .map { (item: Structure) throws -> (Property, Structure) in
                if let variableName = item.dictionary["key.name"] as? String {
                    if let typeName = item.dictionary["key.typename"] as? String {
                        return (Property(name: variableName, type: typeName), item)
                    } else {
                        throw GeneratorError.withMessage("Missing explicit type annotation for property \"\(variableName)\" in \(self.name)")
                    }
                }
                throw GeneratorError.withMessage("Property \(item) does not have a name.")
            }
            .compactMap { (propertyItem: (property: Property, item: Structure)) throws -> Property? in
                if let accessibility = propertyItem.item.dictionary["key.accessibility"] as? String {
                    let isPrivate = (accessibility == "source.lang.swift.accessibility.private")
                    let isFilePrivate = (accessibility == "source.lang.swift.accessibility.fileprivate")
                    if isPrivate || isFilePrivate {
                        info("\(self.name) (\(propertyItem.property.name): \(propertyItem.property.type)) property is \(isPrivate ? "private" : "fileprivate"), therefore inaccessible on DI graph.")
                        return nil
                    } else {
                        return propertyItem.property
                    }
                }
                throw GeneratorError.withMessage("Property missing accessibility identifier.")
        }
    }

    /// The unique set of expression call types in this structure.
    var uniqueExpressionCallNames: [String] {
        let allNames = filterSubstructure(by: "source.lang.swift.expr.call", recursively: true)
            .map { (substructure: Structure) -> String in
                substructure.name
            }
        let set = Set<String>(allNames)
        return Array(set).sorted()
    }

    /// The name of the inherited types of this structure.
    var inheritedTypes: [String] {
        let types = dictionary["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return types.compactMap { (item: SourceKitRepresentable) -> String? in
            ((item as? [String: String])?["key.name"])?.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        }
    }

    private func filterSubstructure(by kind: String, recursively: Bool = false) -> [Structure] {
        let substructures = self.substructures
        let currentLevelSubstructures = substructures.compactMap { (substructure: Structure) -> Structure? in
            if substructure.dictionary["key.kind"] as? String == kind {
                return substructure
            }
            return nil
        }
        if recursively && !substructures.isEmpty {
            return currentLevelSubstructures + substructures.flatMap { (substructure: Structure) -> [Structure] in
                substructure.filterSubstructure(by: kind, recursively: recursively)
            }
        } else {
            return currentLevelSubstructures
        }
    }
}
