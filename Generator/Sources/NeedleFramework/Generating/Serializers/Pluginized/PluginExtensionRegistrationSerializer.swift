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

/// A serializer that produces the registration code for the plugin extension
/// provider.
class PluginExtensionRegistrationSerializer: Serializer {

    /// Initializer.
    ///
    /// - parameter component: The pluginized component to generate registration
    ///   source code for
    init(component: PluginizedComponent) {
        self.component = component
    }

    /// Serialize the data model and produce the registration source code.
    ///
    /// - returns: The registration source code.
    func serialize() -> String {
        let className = PluginExtensionClassNameSerializer(component: component).serialize()
        return """
        __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "\(component.data.name)") { component in
            return \(className)(component: component)
        }\n
        """
    }

    // MARK: - Private

    private let component: PluginizedComponent
}
