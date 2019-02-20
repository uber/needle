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
//  WITHOUT WARRANTIES OR COITIONS OF ANY KI, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Needle internal registry of plugin extension providers.
/// - note: This class is only needed until Swift supports extensions
/// overriding methods. This is an internal class to the Needle dependency
/// injection framework. Application code should never use this class.
// TODO: Remove this once Swift supports extension overriding methods.
// Once that happens, we can declare an `open createPluginExtensionProvider`
// method in the base pluginized component class. Generate extensions to
// all the pluginized component subclasses that override the method to
// instantiate the dependnecy providers.
public class __PluginExtensionProviderRegistry {

    /// The singleton instance.
    public static let instance = __PluginExtensionProviderRegistry()

    /// Register the given factory closure with given key.
    ///
    /// - note: This method is thread-safe.
    /// - note: Plugin extension provider is unique per pluginized component
    /// regardless of its path, since it only extracts properties from its
    /// corresponding non-core component.
    /// - parameter componentName: The name of the component the provider
    /// is for.
    /// - parameter pluginExtensionProviderFactory: The closure that takes
    /// in a component to be injected and returns a provider instance that
    /// conforms to the component's plugin extensions protocol.
    public func registerPluginExtensionProviderFactory(`for` componentName: String, _ pluginExtensionProviderFactory: @escaping (PluginizedScope) -> AnyObject) {
        // Lock on `providerFactories` access.
        lock.lock()
        defer {
            lock.unlock()
        }

        providerFactories[componentName] = pluginExtensionProviderFactory
    }

    func pluginExtensionProvider(`for` component: PluginizedScope) -> AnyObject {
        // Lock on `providerFactories` access.
        lock.lock()
        defer {
            lock.unlock()
        }

        // The last element of the path is the component itself and it always exists.
        let key = component.path.last!
        if let factory = providerFactories[key] {
            return factory(component)
        } else {
            // This case should never occur with properly generated Needle code.
            // This is useful for Needle generator development only.
            fatalError("Missing plugin extension provider factory for \(component.path)")
        }
    }

    private let lock = NSRecursiveLock()
    private var providerFactories = [String: (PluginizedScope) -> AnyObject]()

    private init() {}
}
