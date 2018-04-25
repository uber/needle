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

/// Needle internal registry of dependency providers.
/// - note: This class is only needed until Swift supports extensions overriding methods.
/// This is an internal class to the Needle dependency injection framework. Application
/// code should never use this class directly.
// TODO: Remove this once Swift supports extension overriding methods. Once that happens, we
// can declare an `open createDependencyProvider` method in the base component class. Generate
// extensions to all the component subclasses that override the method to instantiate the
// dependnecy providers.
public class __DependencyProviderRegistry {

    /// The singleton instance.
    public static let instance = __DependencyProviderRegistry()

    /// Register the given factory closure with given key.
    ///
    /// - note: This method is thread-safe.
    /// - note: This method takes in `String` component and parent component names instead of
    /// their metatypes to avoid additional `String` conversion cost. At the same time, the
    /// metatype converted `String` does not contain module prefix, which is important in
    /// resolving name collisions.
    /// - parameter componentName: The fully qualified name of the component that the given
    /// dependency provider factory is for.
    /// - parameter parentComponentName: The fully qualified name of the parent component of
    /// the specified component.
    /// - parameter dependencyProviderFactory: The closure that takes in a component to be
    /// injected and returns a provider instance that conforms to the component's dependency
    /// protocol.
    public func registerDependencyProviderFactory(`for` componentName: String, withParentComponentName parentComponentName: String, _ dependencyProviderFactory: @escaping (ComponentType) -> AnyObject) {
        let key = providerFactoryKey(for: componentName, withParentComponentName: parentComponentName)

        providerFactoryLock.lock()
        defer {
            providerFactoryLock.unlock()
        }

        providerFactories[key] = dependencyProviderFactory
    }

    /// Retrieve the dependency provider for the given component and its parent.
    ///
    /// - parameter component: The component that uses the returned dependency provider.
    /// - returns: The dependency provider for the given component.
    func dependencyProvider(`for` component: ComponentType) -> AnyObject {
        let key = providerFactoryKey(for: component)

        providerFactoryLock.lock()
        defer {
            providerFactoryLock.unlock()
        }

        if let factory = providerFactories[key] {
            return factory(component)
        } else {
            fatalError("Missing dependency provider factory for \(key)")
        }
    }

    private let providerFactoryLock = NSRecursiveLock()
    private var providerFactories = [String: (ComponentType) -> AnyObject]()

    private init() {}

    private func providerFactoryKey(`for` component: ComponentType) -> String {
        let componentName = String(describing: component)
        let parentComponentName = String(describing: component.parent)
        return providerFactoryKey(for: componentName, withParentComponentName: parentComponentName)
    }

    private func providerFactoryKey(`for` componentName: String, withParentComponentName parentComponentName: String) -> String {
        return "\(parentComponentName)->\(componentName)"
    }
}
