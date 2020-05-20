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
import SourceParsingFramework

/// Extension of SourceKitten `Structure` to provide easy access to a set
/// of common AST properties.
extension Structure {

    /// Parse the dependency protocol's type name for the component with
    /// given type name.
    ///
    /// - parameter componentType: The type name of the component.
    /// - returns: The dependency protocol type name.
    /// - throws: 'GenericError` if parsing dependency protocol name from
    /// generics failed.
    func dependencyProtocolName(for componentType: String) throws -> String {
        let regex = Regex("^(\(needleModuleName).)?\(componentType) *<")
        let result = inheritedTypes
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
        if let result = result {
            if result.contains(".") {
                // Contains a module name, strip this out
                return result.components(separatedBy: ".").last ?? result
            }
            return result
        } else {
            throw GenericError.withMessage("\(name) is being parsed as a Component. Yet its generic dependency type cannot be parsed. \(inheritedTypes)")
        }
    }

    /// The properties of this structure.
    ///
    /// - throws: `GenericError` if parsing properties failed.
    func properties() throws -> [Property] {
        return try filterSubstructure(by: "source.lang.swift.decl.var.instance")
            .map { (item: Structure) throws -> (Property, Structure) in
                if let variableName = item.dictionary["key.name"] as? String {
                    if let typeName = item.dictionary["key.typename"] as? String {
                        return (Property(name: variableName, type: typeName), item)
                    } else {
                        throw GenericError.withMessage("Missing explicit type annotation for property \"\(variableName)\" in \(self.name)")
                    }
                }
                throw GenericError.withMessage("Property \(item) does not have a name.")
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
                } else {
                    // If the accessibility identifier is missing it will be internal or private
                    // If it's private it will be caught by the compilation step
                    return propertyItem.property
                }
        }
    }
}
