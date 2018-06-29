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

/// An extended data model representing a dependency provider to be generated
/// for a specific path of a component.
struct PluginizedProcessedDependencyProvider {
    /// The actual data of this dependency provider.
    /// Note that in this struct, the `processedProperties` are always empty
    let data: ProcessedDependencyProvider
    /// This is a (richer) replacement for the processed properties in the data
    /// struct
    let processedProperties: [PluginizedProcessedProperty]

    /// Initializer.
    ///
    /// - parameter unprocessed: The unprocessed data model.
    /// - parameter levelMap: The map of component type names to the number of
    /// levels between provider and component that needs it. to check for
    /// auxiliary properties.
    /// - parameter processedProperties: TThe properties with their source
    /// components filled in.
    init(unprocessed: DependencyProvider, levelMap: [String: Int], processedProperties: [PluginizedProcessedProperty]) {
        self.data = ProcessedDependencyProvider(unprocessed: unprocessed, levelMap: levelMap, processedProperties: [])
        self.processedProperties = processedProperties
    }
}
