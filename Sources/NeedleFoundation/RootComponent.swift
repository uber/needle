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

/// The base implementation of a component thet represents the root of
/// a dependency graph. A subclass defining the root scope should
/// inherit from this class instead of the generic `Component` class.
///
/// - SeeAlso: `Component`.
open class RootComponent: Component<EmptyDependency> {

    /// Initializer.
    public init() {
        super.init(parent: BootstrapComponent())
    }
}
