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
/// Note: We're using a class here because (among other reasons) we have a mutable list
/// of parents which we plan to add to one element at a time, while maintaing the tree structure.
class Component {
    /// The name of the component.
    let name: String
    /// The name of the component's dependency protocol.
    let dependencyProtocolName: String
    /// A list of properties this component instantiates, thereby provides.
    let properties: [Property]
    /// A list of expression call type names.
    let expressionCallTypeNames: [String]
    /// A list of parent components
    /// While we expect to update this from only one thread, it may be read from multiple
    /// threads, and we need to be careful about synchronization in that case
    var parents : [Component]

    init(name: String, dependencyProtocolName: String, properties: [Property], expressionCallTypeNames: [String]) {
        self.name = name
        self.dependencyProtocolName = dependencyProtocolName
        self.properties = properties
        self.expressionCallTypeNames = expressionCallTypeNames
        self.parents = []
    }
}
