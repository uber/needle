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

/// The base protocol for a scope that's pluginized. It defines the
/// pairing methods to manage its and its corresponding non-core
/// scope's lifecycle.
///
/// - note: A separate protocol is used to allow the consumer to declare
/// a pluginized component generic without having to specify the nested
/// generics.
/// @CreateMock
public protocol PluginizedScope: Scope {
    /// Bind the pluginized component to the given lifecycle. This ensures
    /// the associated non-core component is notified and released according
    /// to the given scope's lifecycle.
    ///
    /// - note: This method must be invoked when using a `PluginizedComponent`,
    /// to avoid memory leak of the component and the non-core component.
    /// - note: This method is required, because the non-core component
    /// reference cannot be made weak. If the non-core component is weak,
    /// it is deallocated before the plugin points are created lazily.
    /// - parameter observable: The `PluginizedScopeLifecycleObservable` to
    /// bind to.
    func bind(to observable: PluginizedScopeLifecycleObservable)
}

/// The base protocol of a plugin extension, enabling Needle's parsing process.
public protocol PluginExtension: AnyObject {}

#if NEEDLE_DYNAMIC

public protocol ExtensionRegistration {
    func registerExtensionItems()
}

@dynamicMemberLookup
public class PluginExtensionProvider<DependencyType, PluginExtensionType, NonCoreComponent: NonCoreScope> {
    
    /// The parent component of this provider.
    public let component: PluginizedComponent<DependencyType, PluginExtensionType, NonCoreComponent>
    
    init(component: PluginizedComponent<DependencyType, PluginExtensionType, NonCoreComponent>) {
        self.component = component
    }

    public func find<T>(property: String) -> T {
        // Plugin extension protocols don't allow you to "walk" up the tree, just check at the same level
        guard let nonCore = (component.nonCoreComponent as? NonCoreScope) else {
            fatalError("Non-core component of incorrect type: \(type(of: component.nonCoreComponent))")
        }
        guard let result: T = nonCore.check(property: property) else {
            fatalError("Property \(property) not found in non-core component \(nonCore)")
        }
        return result
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<PluginExtensionType, T>) -> T {
        guard let propertyName = component.extensionToName[keyPath] else {
             fatalError("Cound not find \(keyPath) in lookup table")
        }
        return find(property: propertyName)
    }

}

#endif

/// The base pluginized component class. All core components that involve
/// plugins should inherit from this class.
open class PluginizedComponent<DependencyType, PluginExtensionType, NonCoreComponent: NonCoreScope>: Component<DependencyType>, PluginizedScope {

    /// The plugin extension granting access to plugin points provided by
    /// the corresponding non-core component of this component.

    #if NEEDLE_DYNAMIC
    public private(set) var pluginExtension: PluginExtensionProvider<DependencyType, PluginExtensionType, NonCoreComponent>!
    #else
    public private(set) var pluginExtension: PluginExtensionType!
    #endif

    /// The type-erased non-core component instance. Subclasses should not
    /// directly access this property.
    public var nonCoreComponent: AnyObject {
        guard let value = releasableNonCoreComponent else {
            // This case should not occur if the pluginized component is properly
            // paired with a consumer. This only occurs if the `nonCoreComponent`
            // is accessed after the `consumerWillDeinit` method is invoked.
            fatalError("Attempt to access non-core component of \(self) after it has been released.")
        }
        return value
    }

    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public override init(parent: Scope) {
        #if NEEDLE_DYNAMIC
        super.init(parent: parent, nonCore: true)
        releasableNonCoreComponent = NonCoreComponent(parent: self)
        if let registerable = self as? ExtensionRegistration {
            registerable.registerExtensionItems()
        }
        pluginExtension = PluginExtensionProvider(component: self)
        #else
        super.init(parent: parent)
        releasableNonCoreComponent = NonCoreComponent(parent: self)
        pluginExtension = createPluginExtensionProvider()
        #endif
    }

    /// Bind the pluginized component to the given lifecycle. This ensures
    /// the associated non-core component is notified and released according
    /// to the given scope's lifecycle.
    ///
    /// - note: This method must be invoked when using a `PluginizedComponent`,
    /// to avoid memory leak of the component and the non-core component.
    /// - note: This method is required, because the non-core component
    /// reference cannot be made weak. If the non-core component is weak,
    /// it is deallocated before the plugin points are created lazily.
    /// - parameter observable: The `PluginizedScopeLifecycleObservable` to
    /// bind to.
    public func bind(to observable: PluginizedScopeLifecycleObservable) {
        guard lifecycleObserverDisposable == nil else {
            return
        }

        lifecycleObserverDisposable = observable.observe { (event: PluginizedScopeLifecycle) in
            switch event {
            case .active:
                self.releasableNonCoreComponent?.scopeDidBecomeActive()
            case .inactive:
                self.releasableNonCoreComponent?.scopeDidBecomeInactive()
            case .deinit:
                self.scopeWillDeinit()
                
                // Only release the non-core component after the consumer, which should
                // be the owner reference to the component is released. Cannot release
                // the non-core component when the bound lifecyle is deactivated. The
                // consumer may later require the same instance of this component again.
                // In that case, this component will try to access its released non-core
                // component to recreate plugins.
                self.releasableNonCoreComponent = nil
            }
        }
    }
    
    /// Indicates that the corresponding scope will deinit
    ///
    /// - note: This method is automatically invoked when the bound `PluginizedScopeLifecycleObservable`
    /// enters its `deinit` state
    open func scopeWillDeinit() {}

    // MARK: - Private

    private var lifecycleObserverDisposable: ObserverDisposable?

    // Must retain the non-core component so it doesn't get deallocated before it's used
    // to pull plugin points, since the plugin points are created lazily.
    private var releasableNonCoreComponent: NonCoreScope?

    // TODO: Replace this with an `open` method, once Swift supports extension overriding methods.
    private func createPluginExtensionProvider() -> PluginExtensionType {
        let provider = __PluginExtensionProviderRegistry.instance.pluginExtensionProvider(for: self)
        if let pluginExtension = provider as? PluginExtensionType {
            return pluginExtension
        } else {
            // This case should never occur with properly generated Needle code.
            // Needle's official generator should guarantee the correctness.
            fatalError("Plugin extension provider factory for \(self) returned incorrect type. Should be of type \(String(describing: PluginExtensionType.self)). Actual type is \(String(describing: provider))")
        }
    }

    #if NEEDLE_DYNAMIC
    
    public var extensionToName = [PartialKeyPath<PluginExtensionType>:String]()

    override public func find<T>(property: String, skipThisLevel: Bool) -> T {
        if let itemCloure = localTable[property] {
            guard let result = itemCloure() as? T else {
                fatalError("Incorrect type for \(property) found lookup table")
            }
            return result
        } else {
            if let releasableNonCoreComponent = releasableNonCoreComponent, !skipThisLevel, let result: T = releasableNonCoreComponent.check(property: property) {
                return result
            } else {
                return parent.find(property: property, skipThisLevel: false)
            }
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<PluginExtensionType, T>) -> T {
        guard let propertyName = extensionToName[keyPath] else {
             fatalError("Cound not find \(keyPath) in lookup table")
        }
        return find(property: propertyName, skipThisLevel: false)
    }
    
    #endif
    
    deinit {
        guard let lifecycleObserverDisposable = lifecycleObserverDisposable else {
            // This occurs with improper usages of a pluginized component. It
            // should be bound to a lifecycle allowing the non-core component
            // to trigger its lifecycle.
            fatalError("\(self) should be bound to its corresponding lifecyle to avoid memory leaks.")
        }
        lifecycleObserverDisposable.dispose()
    }
}
