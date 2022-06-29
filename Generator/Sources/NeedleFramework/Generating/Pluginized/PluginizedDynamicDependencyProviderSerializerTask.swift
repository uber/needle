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

/// The task that serializes a list of pluginized processed dependency
/// providers into exportable foramt.
class PluginizedDynamicDependencyProviderSerializerTask: AbstractTask<[SerializedProvider]> {

    /// Initializer.
    ///
    /// - parameter providers: The pluginized processed dependency provider
    /// to serialize.
    init(component: Component, providers: [PluginizedProcessedDependencyProvider]) {
        self.component = component
        self.providers = providers
        super.init(id: TaskIds.pluginizedDependencyProviderSerializerTask.rawValue)
    }

    /// Execute the task and returns the in-memory serialized dependency
    /// provider data models.
    ///
    /// - returns: The list of `SerializedProvider`.
    override func execute() -> [SerializedProvider] {
        guard !providers.isEmpty else {
            return []
        }
        let serilizer = DependencyPropsSerializer(component: component)
        let result = SerializedProvider(content: serilizer.serialize(), registration: "", attributes: ProviderAttributes())
        return [result]
    }

    // MARK: - Private

    private let component: Component
    private let providers: [PluginizedProcessedDependencyProvider]
}
