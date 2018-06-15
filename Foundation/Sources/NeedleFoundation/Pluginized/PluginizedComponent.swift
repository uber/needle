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

/// The base protocol for a component that's pluginized. It defines the
/// pairing methods to manage its and its corresponding non-core component's
/// lifecycle.
///
/// - note: A separate protocol is used to allow `PluginizedBuilder` to
/// delcare a pluginized component generic without having to specify the
/// nested generics.
public protocol PluginizedComponentType: ComponentType {
    /// Bind the plugnizable component to the router's lifecycle. This ensures
    /// the associated non-core component is released when the given router scope
    /// is deallocated.
    ///
    /// - note: This method must be invoked when using a `PluginizedComponent`,
    /// to avoid memory leak of the component and the non-core component.
    /// - note: This method is required, because the non-core component reference
    /// cannot be made weak. If the non-core component is weak, it is deallocated
    /// before the plugin points are created lazily.
    /// - parameter lifecycle: The `PluginizedLifecycle` to bind to.
    func bind(to lifecycle: PluginizedLifecycle)

    /// Signal the corresponding `PluginizedBuilder` is about to deinit.
    /// This allows the pluginized component to release its corresponding
    /// non-core component, breaking the retain cycle between it and its
    /// non-core component.
    func builderWillDeinit()
}

/// The base pluginized component class. All core components that involve
/// plugins should inherit from this class.
open class PluginizedComponent<DependencyType, PluginExtensionType, NonCoreComponent: NonCoreComponentType>: Component<DependencyType>, PluginizedComponentType {

    /// The plugin extension granting access to plugin points provided by
    /// the corresponding non-core component of this component.
    public private(set) var pluginExtension: PluginExtensionType!

    /// The type-erased non-core component instance. Subclasses should not
    /// directly access this property.
    public var nonCoreComponent: AnyObject {
        guard let value = releasableNonCoreComponent else {
            fatalError("Attempt to access non-core component of \(self) after it has been released.")
        }
        return value
    }

    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public override init(parent: ComponentType) {
        super.init(parent: parent)
        releasableNonCoreComponent = NonCoreComponent(parent: self)
        pluginExtension = createPluginExtensionProvider()
    }

    /// Bind the plugnizable component to the router's lifecycle. This ensures
    /// the associated non-core component is released when the given router scope
    /// is deallocated.
    ///
    /// - note: This method must be invoked when using a `PluginizedComponent`,
    /// to avoid memory leak of the component and the non-core component.
    /// - note: This method is required, because the non-core component reference
    /// cannot be made weak. If the non-core component is weak, it is deallocated
    /// before the plugin points are created lazily.
    /// - parameter lifecycle: The `PluginizedLifecycle` to bind to.
    public func bind(to lifecycle: PluginizedLifecycle) {
        guard lifecycleObserverDisposable == nil else {
            return
        }

        lifecycleObserverDisposable = lifecycle.observe { (isActive: Bool) in
            if isActive {
                self.releasableNonCoreComponent?.scopeDidBecomeActive()
            } else {
                self.releasableNonCoreComponent?.scopeDidBecomeInactive()
            }
        }
    }

    /// Signal the corresponding `PluginizedBuilder` is about to deinit.
    /// This allows the pluginized component to release its corresponding
    /// non-core component, breaking the retain cycle between it and its
    /// non-core component.
    public func builderWillDeinit() {
        // Only release the non-core component after the builder, which should be the owner
        // reference to the component is released. Cannot release the non-core component when
        // the bound router is detached. The builder may build another instance of the RIB
        // with the same instance of this component again. In that case, this component will
        // try to access its released non-core component to recreate plugin points.
        self.releasableNonCoreComponent = nil
    }

    // MARK: - Private

    private var lifecycleObserverDisposable: ObserverDisposable?

    // Must retain the non-core component so it doesn't get deallocated before it's used
    // to pull plugin points, since the plugin points are created lazily.
    private var releasableNonCoreComponent: NonCoreComponentType?

    // TODO: Replace this with an `open` method, once Swift supports extension overriding methods.
    private func createPluginExtensionProvider() -> PluginExtensionType {
        let provider = __PluginExtensionProviderRegistry.instance.pluginExtensionProvider(for: self)
        if let pluginExtension = provider as? PluginExtensionType {
            return pluginExtension
        } else {
            fatalError("Plugin extension provider factory for \(self) returned incorrect type. Should be of type \(String(describing: PluginExtensionType.self)). Actual type is \(String(describing: provider))")
        }
    }

    deinit {
        guard let lifecycleObserverDisposable = lifecycleObserverDisposable else {
            fatalError("\(self) should be bound to its corresponding lifecyle to avoid memory leaks.")
        }
        lifecycleObserverDisposable.dispose()
    }
}
