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
public extension Structure {

    /// The substructures of this structure.
    public var substructures: [Structure] {
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
    public var name: String {
        /// The type name of this structure.
        return dictionary["key.name"] as! String
    }

    /// The unique set of expression call types in this structure.
    public var uniqueExpressionCallNames: [String] {
        let allNames = filterSubstructure(by: "source.lang.swift.expr.call", recursively: true)
            .map { (substructure: Structure) -> String in
                substructure.name
            }
        let set = Set<String>(allNames)
        return Array(set).sorted()
    }

    /// The name of the inherited types of this structure.
    public var inheritedTypes: [String] {
        let types = dictionary["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return types.compactMap { (item: SourceKitRepresentable) -> String? in
            ((item as? [String: String])?["key.name"])?.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
        }
    }

    /// Filter out substructures with the given `key.kind` value.
    ///
    /// - parameter kind: The `key.kind` value to filter for.
    /// - parameter recursively: If the filter should include
    /// nested substructures.
    /// - returns: The matching structures.
    public func filterSubstructure(by kind: String, recursively: Bool = false) -> [Structure] {
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
