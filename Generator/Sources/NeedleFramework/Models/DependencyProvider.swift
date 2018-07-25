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

/// The data model representing a dependency provider to be generated for a
/// specific path of a component.
struct DependencyProvider {
    /// The path starting at the component that declares the dependency protocol.
    let path: [Component]
    /// The dependency protocol declared.
    let dependency: Dependency

    /// The path in `String` format.
    var pathString: String {
        return "^->" + path
            .map { (component: Component) -> String in
                component.name
            }
            .joined(separator: "->")
    }
}

/// The data model representing a dependency provider to be generated for a
/// specific path of a component.
struct ProcessedDependencyProvider {
    /// The unprocessed data model.
    let unprocessed: DependencyProvider
    /// The map of component type names to the number of levels between the requiring
    /// component and the providing compoennt. The key is the type of the component
    /// that provides one of the dependencies.
    let levelMap: [String: Int]
    /// The properties with their source components filled in.
    let processedProperties: [ProcessedProperty]

    /// `true` if this provider's dependency prootocol is the `EmptyDependency`.
    /// `false` otherwise.
    var isEmptyDependency: Bool {
        return unprocessed.dependency.isEmptyDependency
    }
}

/// The data model representing a fully serialized provider ready for
/// export.
struct SerializedProvider {
    /// The dependency provider class content code.
    let content: String
    /// The dependency provider registration code.
    let registration: String
}
