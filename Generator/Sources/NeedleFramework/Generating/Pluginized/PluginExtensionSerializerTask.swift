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

import Concurrency
import Foundation

/// The task that generates the declaration and registration of the
/// plugin extension provider for a specific pluginized component.
class PluginExtensionSerializerTask : AbstractTask<SerializedProvider> {

    /// Initializer.
    ///
    /// - parameter component: The pluginized component that requires the
    /// plugin extension provider.
    init(component: PluginizedComponent) {
        self.component = component
        super.init(id: TaskIds.pluginExtensionSerializerTask.rawValue)
    }

    /// Execute the task and returns the data model.
    ///
    /// - returns: The `SerializedProvider`.
    override func execute() -> SerializedProvider {
        let content = PluginExtensionContentSerializer(component: component).serialize()
        let registration = PluginExtensionRegistrationSerializer(component: component).serialize()
        return SerializedProvider(content: content, registration: registration)
    }

    // MARK: - Private

    private let component: PluginizedComponent

}
