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

/// The special empty dependency data model.
let emptyDependency = Dependency(name: "EmptyDependency", properties: [], sourceHash: "UniqueEmptyDependencyHash")

/// A data model representing a dependency protocol of a NeedleFoundation
/// `Component`.
// This is separate from the `Component` data model, since a component's
// dependency protocol may be declared in a separate file.
struct Dependency: Equatable {
    /// The name of the dependency protocol.
    let name: String
    /// The list of dependency properties.
    let properties: [Property]
    /// The file where this dependency  is declared
    let sourceHash: String

    /// `true` if this dependency prootocol is the `EmptyDependency`.
    /// `false` otherwise.
    var isEmptyDependency: Bool {
        return Dependency.isEmptyDependency(name: name)
    }

    /// Check if the dependency name is an empty dependency.
    ///
    /// - returns: `true` if this dependency prootocol is the `EmptyDependency`.
    /// `false` otherwise.
    static func isEmptyDependency(name: String) -> Bool {
        return name == "EmptyDependency"
    }
}
