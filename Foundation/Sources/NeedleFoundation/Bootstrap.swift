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

/// An empty protocol that can be used for any components that require no dependencies. This
/// can be used as the dependnecy protocol of the root component of a dependency graph.
public protocol EmptyDependency {}

/// The dependency provider that conforms to `EmptyDependency`. This is used to bootstrap the
/// root component of a dependency graph.
public class EmptyDependencyProvider: EmptyDependency {

    /// Initializer.
    public init() {}
}

/// An empty class that can be used as the bootstrap component, the parent component of the
/// root component in the dependency graph.
public class BootstrapComponent: Scope {

    /// The path to reach this scope on the dependnecy graph.
    public let path: String = "^"

    /// Initializer.
    public init() {}
}
