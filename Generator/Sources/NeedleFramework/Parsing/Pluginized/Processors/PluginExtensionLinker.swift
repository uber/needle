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

/// A processor that links pluginized components with their plugin
/// extensions based on type name.
class PluginExtensionLinker: Processor {

    /// Initializer.
    ///
    /// - parameter pluginizedComponents: The pluginized components to
    /// link with plugin extensions.
    /// - parameter pluginExtensions: The non-core components to link.
    init(pluginizedComponents: [PluginizedASTComponent], pluginExtensions: [PluginExtension]) {
        self.pluginizedComponents = pluginizedComponents
        self.pluginExtensions = pluginExtensions
    }

    /// Process the data models.
    ///
    /// - throws: `ProcessingError` if some pluginized components cannot
    /// find matching plugin extensions.
    func process() throws {
        var extensionMap = [String: PluginExtension]()
        for pluginExtension in pluginExtensions {
            extensionMap[pluginExtension.name] = pluginExtension
        }

        for pluginizedComponent in pluginizedComponents {
            pluginizedComponent.pluginExtension = extensionMap[pluginizedComponent.pluginExtensionType]
            if pluginizedComponent.pluginExtension == nil {
                throw GenericError.withMessage("Cannot find \(pluginizedComponent.data.name)'s plugin extension with type name \(pluginizedComponent.pluginExtensionType)")
            }
        }
    }

    // MARK: - Private

    private let pluginizedComponents: [PluginizedASTComponent]
    private let pluginExtensions: [PluginExtension]
}
