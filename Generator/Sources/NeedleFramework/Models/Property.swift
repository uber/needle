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

/// A data model representing a dependency property that is either provided by a
/// `Component` or required by one.
struct Property: Hashable {
    /// The variable name.
    let name: String
    /// The property type `String`.
    let type: String
}

/// A data model representing a single dependency property that has gone through
/// generation processing.
struct ProcessedProperty: Equatable, Hashable {
    /// The unprocessed property we started with.
    let unprocessed: Property
    /// Type of the Component where this property is satisfied.
    let sourceComponentType: String
}
