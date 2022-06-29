//
//  PluginExtensionDynamicSerializerTask.swift
//  
//
//  Created by Rudro Samanta on 7/1/22.
//

import Concurrency
import Foundation

/// The task that generates the declaration and registration of the
/// plugin extension provider for a specific pluginized component.
class PluginExtensionDynamicSerializerTask : AbstractTask<SerializedProvider> {

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
        let content = PluginExtensionDynamicContentSerializer(component: component).serialize()
        return SerializedProvider(content: content, registration: "", attributes: ProviderAttributes())
    }

    // MARK: - Private

    private let component: PluginizedComponent
}
