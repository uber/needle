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
import SourceParsingFramework

/// A post processing utility class that checks if there are any cycles
/// in any of the pluginized components their plugin extensions.
///
/// - note: This validator requires all plugin extensions and non-core
/// components have already been linked with their corresponding pluginized
/// components.
class PluginExtensionCycleValidator: Processor {

    /// Initializer.
    ///
    /// - parameter pluginizedComponents: The list of pluginized components
    /// to validate.
    init(pluginizedComponents: [PluginizedASTComponent]) {
        self.pluginizedComponents = pluginizedComponents
    }

    /// Process the data models.
    ///
    /// - throws: `ProcessingError` if any cycles are detected.
    func process() throws {
        for component in pluginizedComponents {
            guard let pluginExtension = component.pluginExtension else {
                throw GenericError.withMessage("\(component.data.name)'s plugin extension has not been linked.")
            }
            guard let nonCoreDependency = component.nonCoreComponent?.dependencyProtocol else {
                throw GenericError.withMessage("\(component.data.name)'s non-core component dependency has not been linked.")
            }

            let nonCoreDepProperties = Set<Property>(nonCoreDependency.properties)
            let pluginExtensionProperties = Set<Property>(pluginExtension.properties)
            let componentProperties = Set<Property>(component.data.properties)
            // This isn't an exact cycle matching, since we cannot check for
            // how the property is provided by the core component. This just
            // checks that core component provides a property which is also
            // required by the plugin extension and the non-core component dependency.
            // SourceKit does not provide the last bit of information, where the
            // core component provides the property via `pluginExtension.property`.
            // In this case, we are assuming the property is provided via the
            // plugin extension, since it lists it, therefore causing a cycle.
            let intersections = nonCoreDepProperties.intersection(pluginExtensionProperties).intersection(componentProperties)
            if !intersections.isEmpty {
                let cyclicPropertiesString = intersections
                    .map { (property: Property) -> String in
                        return "(\(property.name): \(property.type))"
                    }
                    .joined(separator: ", ")
                throw GenericError.withMessage("\(component.data.name) contains cyclic plugin extension properties \(cyclicPropertiesString).")
            }
        }
    }

    // MARK: - Private

    private let pluginizedComponents: [PluginizedASTComponent]
}
