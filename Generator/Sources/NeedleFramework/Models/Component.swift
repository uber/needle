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

/// A data model representing a dependency graph scope declared by a NeedleFoundation
/// `Component` subclass.
struct Component: Equatable {
    /// The name of the component.
    let name: String
    /// Indicates if this component is the root of a dependency graph.
    let isRoot: Bool
    /// A list of properties this component instantiates, thereby provides.
    let properties: [Property]
    /// A list of parent components.
    let parents : [Component]
    /// The dependency protocol data model.
    let dependency: Dependency
}

/// A intermediate data model representing a component parsed straight out of
/// the source file AST. This model does not include the necessary references
/// to other related models, such as the dependency protocol.
/// - note: This data structure is mutated to link child-parent instances. Therefore,
/// this needs to be a reference type.
class ASTComponent {
    /// The name of the component.
    let name: String
    /// The name of the component's dependency protocol.
    let dependencyProtocolName: String
    /// Indicates if this component is the root of a dependency graph.
    let isRoot: Bool
    /// The  hash of the source file where this ASTComponent was declared
    let sourceHash: String
    /// A list of properties this component instantiates, thereby provides.
    var properties: [Property]
    /// A list of expression call type names.
    var expressionCallTypeNames: [String]
    /// The mutable list of parents.
    var parents = [ASTComponent]()
    /// The referenced dependency protocol data model.
    var dependencyProtocol: Dependency?

    /// Convert the mutable reference type into a thread-safe value type.
    var valueType: Component {
        let parentValues = parents.map { (parent: ASTComponent) -> Component in
            parent.valueType
        }
        return Component(name: name, isRoot: isRoot, properties: properties, parents: parentValues, dependency: dependencyProtocol!)
    }

    /// Initializer.
    init(name: String, dependencyProtocolName: String, isRoot: Bool, sourceHash: String, properties: [Property], expressionCallTypeNames: [String]) {
        self.name = name
        self.dependencyProtocolName = dependencyProtocolName
        self.isRoot = isRoot
        self.sourceHash = sourceHash
        self.properties = properties
        self.expressionCallTypeNames = expressionCallTypeNames
    }
}

/// A intermediate data model representing an extension of a component parsed
/// straight out of the source file AST. This data model does not represent a
/// complete component scope. Instead it is linked with the `ASTComponent` to
/// for a complete representation.
struct ASTComponentExtension {
    /// The name of the component.
    let name: String
    /// A list of properties this component instantiates, and thereby provides.
    let properties: [Property]
    /// A list of expression call type names.
    let expressionCallTypeNames: [String]
}
