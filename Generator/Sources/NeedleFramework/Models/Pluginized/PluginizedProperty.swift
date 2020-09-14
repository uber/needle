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

/// When a property is found is the auxillary source, this lets us know the
/// source
enum AuxillarySourceType {
    /// Situation where a core component is getting a property from the
    /// plugin extension protocol.
    case pluginExtension
    /// Situation where a non-core component gets the property from a
    /// ancestor non-core component.
    case nonCoreComponent
}

/// An extended data model representing a single dependency property that
/// has gone through generation processing.
struct PluginizedProcessedProperty: Equatable, Hashable {
    /// The actual data of this dependency property.
    let data: ProcessedProperty
    /// If the property was found in the auxillary scope, this tells us the
    /// type of that scope.
    let auxillarySourceType: AuxillarySourceType?
    /// If the property was found in the auxillary scope, this is the type
    /// name of the auxillary object.
    let auxillarySourceName: String?
}
