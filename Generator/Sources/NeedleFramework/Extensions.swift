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

extension Dictionary where Key: ExpressibleByStringLiteral {

    /// Accessibility.
    var accessibility: String? {
        return self["key.accessibility"] as? String
    }
    /// Body length.
    var bodyLength: Int? {
        return (self["key.bodylength"] as? Int64).flatMap({ Int($0) })
    }
    /// Body offset.
    var bodyOffset: Int? {
        return (self["key.bodyoffset"] as? Int64).flatMap({ Int($0) })
    }
    /// Kind.
    var kind: String? {
        return self["key.kind"] as? String
    }
    /// Length.
    var length: Int? {
        return (self["key.length"] as? Int64).flatMap({ Int($0) })
    }
    /// Name.
    var name: String? {
        return self["key.name"] as? String
    }
    /// Name length.
    var nameLength: Int? {
        return (self["key.namelength"] as? Int64).flatMap({ Int($0) })
    }
    /// Name offset.
    var nameOffset: Int? {
        return (self["key.nameoffset"] as? Int64).flatMap({ Int($0) })
    }
    /// Offset.
    var offset: Int? {
        return (self["key.offset"] as? Int64).flatMap({ Int($0) })
    }
    /// Setter accessibility.
    var setterAccessibility: String? {
        return self["key.setter_accessibility"] as? String
    }
    /// Type name.
    var typeName: String? {
        return self["key.typename"] as? String
    }

    var substructure: [[String: SourceKitRepresentable]] {
        let substructure = self["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { $0 as? [String: SourceKitRepresentable] }
    }

    var inheritedTypes: [String] {
        let array = self["key.inheritedtypes"] as? [SourceKitRepresentable] ?? []
        return array.flatMap { ($0 as? [String: String])?.name }
    }
}
