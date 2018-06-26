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

/// A processor that links pluginizable components with their plugin
/// extensions based on type name.
class PluginExtensionLinker: Processor {

    /// Initializer.
    ///
    /// - parameter pluginizableComponents: The pluginizable components to
    /// link with plugin extensions.
    /// - parameter pluginExtensions: The non-core components to link.
    init(pluginizableComponents: [PluginizableASTComponent], pluginExtensions: [PluginExtension]) {
        self.pluginizableComponents = pluginizableComponents
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

        for pluginizableComponent in pluginizableComponents {
            pluginizableComponent.pluginExtension = extensionMap[pluginizableComponent.pluginExtensionType]
            if pluginizableComponent.pluginExtension == nil {
                throw ProcessingError.fail("Cannot find \(pluginizableComponent.data.name)'s plugin extension with type name \(pluginizableComponent.pluginExtensionType)")
            }
        }
    }

    // MARK: - Private

    private let pluginizableComponents: [PluginizableASTComponent]
    private let pluginExtensions: [PluginExtension]
}
