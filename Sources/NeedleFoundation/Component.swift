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

/// The base protocol of a dependency, enabling Needle's parsing process.
public protocol Dependency: AnyObject {}

#if NEEDLE_DYNAMIC
public protocol Registration {
    func registerItems()
}
#endif

/// The base protocol of a DI scope. Application code should inherit
/// from the `Component` base class, instead of using this protocol
/// directly.
/// @CreateMock
public protocol Scope: AnyObject {
    /// The path to reach this component on the dependency graph.
    var path: [String] { get }

    /// The parent of this component.
    var parent: NeedleFoundation.Scope { get }
    
    #if NEEDLE_DYNAMIC
    func find<T>(property: String, skipThisLevel: Bool) -> T
    #endif
}

#if NEEDLE_DYNAMIC

@dynamicMemberLookup
public class DependencyProvider<DependencyType> {
    
    /// The parent component of this provider.
    weak var component: Component<DependencyType>?
    let nonCore: Bool

    init(component: Component<DependencyType>, nonCore: Bool) {
        self.component = component
        self.nonCore = nonCore
    }

    public func find<T>(property: String) -> T {
        return component!.parent.find(property: property, skipThisLevel: nonCore)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<DependencyType, T>) -> T {
        return lookup(keyPath: keyPath)
    }
    
    public func lookup<T>(keyPath: KeyPath<DependencyType, T>) -> T {
        guard let propertyName = component!.keyPathToName[keyPath] else {
             fatalError("Cound not find \(keyPath) in lookup table")
        }
        return find(property: propertyName)
    }

}

/// The base implementation of a dependency injection component. A subclass
/// defines a unique scope within the dependency injection tree, that
/// contains a set of properties it provides to units of its scope as well
/// as child scopes. A component instantiates child components that define
/// child scopes.
@dynamicMemberLookup
open class Component<DependencyType>: Scope {
    
    /// The parent of this component.
    public let parent: Scope

    /// The path to reach this scope on the dependency graph.
    // Use `lazy var` to avoid computing the path repeatedly. Internally,
    // this is always accessed with the `__DependencyProviderRegistry`'s lock
    // acquired.
    public lazy var path: [String] = {
        let name = self.name
        return parent.path + ["\(name)"]
    }()

    /// The dependency of this component.
    ///
    /// - note: Accessing this property is not thread-safe. It should only be
    /// accessed on the same thread as the one that instantiated this component.
    public private(set) var dependency: DependencyProvider<DependencyType>!

    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public init(parent: Scope) {
        self.parent = parent
        if let canRegister = self as? Registration {
            canRegister.registerItems()
        }
        dependency = DependencyProvider(component: self, nonCore: false)
    }
    
    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public init(parent: Scope, nonCore: Bool) {
        self.parent = parent
        
        if let canRegister = self as? Registration {
            canRegister.registerItems()
        }
        dependency = DependencyProvider(component: self, nonCore: nonCore)
    }
    
    /// Share the enclosed object as a singleton at this scope. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads
    /// as it may cause a deadlock.
    ///
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func shared<T>(__function: StaticString = #function, _ factory: () -> T) -> T {
        return shared(__function: __function, args: Nothing(), factory)
    }

    /// Share the enclosed object as a singleton at this scope based on the `args` parameter. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause a deadlock.
    ///
    /// - parameter args: A value that conforms to the `Hashable` protocol to differentiate between singleton instances.
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func shared<Args: Hashable, T>(__function: StaticString = #function, args: Args, _ factory: () -> T) -> T {
        sharedInstanceLock.lock()
        defer {
            sharedInstanceLock.unlock()
        }

        return storage.shared(function: __function, args: args, factory: factory)
    }

    /// Share the enclosed object as a weak singleton at this scope. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause a deadlock.
    ///
    /// - note: This function is only applicable for reference types (classes).
    ///
    /// - parameter args: A value that conforms to the `Hashable` protocol to differentiate between singleton instances.
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func weakShared<T: AnyObject>(__function: StaticString = #function, _ factory: () -> T) -> T {
        return weakShared(__function: __function, args: Nothing(), factory)
    }

    /// Share the enclosed object as a weak singleton at this scope based on the `args` parameter. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause a deadlock.
    ///
    /// - note: This function is only applicable for reference types (classes).
    ///
    /// - parameter args: A value that conforms to the `Hashable` protocol to differentiate between singleton instances.
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func weakShared<Args: Hashable, T: AnyObject>(__function: StaticString = #function, args: Args, _ factory: () -> T) -> T {
        sharedInstanceLock.lock()
        defer {
            sharedInstanceLock.unlock()
        }

        return storage.weakShared(function: __function, args: args, factory: factory)
    }

    public func find<T>(property: String, skipThisLevel: Bool) -> T {
        guard let itemCloure = localTable[property] else {
            return parent.find(property: property, skipThisLevel: false)
        }
        guard let result = itemCloure() as? T else {
            fatalError("Incorrect type for \(property) found lookup table")
        }
        return result
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<DependencyType, T>) -> T {
        return dependency.lookup(keyPath: keyPath)
    }

    public var localTable = [String:()->Any]()
    public var keyPathToName = [PartialKeyPath<DependencyType>:String]()

    // MARK: - Private

    private let sharedInstanceLock = NSRecursiveLock()

    private let storage = AssemblyStorage()
    private lazy var name: String = {
        let fullyQualifiedSelfName = String(describing: self)
        let parts = fullyQualifiedSelfName.components(separatedBy: ".")
        return parts.last ?? fullyQualifiedSelfName
    }()

    // TODO: Replace this with an `open` method, once Swift supports extension
    // overriding methods.
    private func createDependencyProvider() -> DependencyType {
        let provider = __DependencyProviderRegistry.instance.dependencyProvider(for: self)
        if let dependency = provider as? DependencyType {
            return dependency
        } else {
            // This case should never occur with properly generated Needle code.
            // Needle's official generator should guarantee the correctness.
            fatalError("Dependency provider factory for \(self) returned incorrect type. Should be of type \(String(describing: DependencyType.self)). Actual type is \(String(describing: dependency))")
        }
    }
}

#else

/// The base implementation of a dependency injection component. A subclass
/// defines a unique scope within the dependency injection tree, that
/// contains a set of properties it provides to units of its scope as well
/// as child scopes. A component instantiates child components that define
/// child scopes.
@dynamicMemberLookup
open class Component<DependencyType>: Scope {

    /// The parent of this component.
    public let parent: Scope

    /// The path to reach this scope on the dependency graph.
    // Use `lazy var` to avoid computing the path repeatedly. Internally,
    // this is always accessed with the `__DependencyProviderRegistry`'s lock
    // acquired.
    public lazy var path: [String] = {
        let name = self.name
        return parent.path + ["\(name)"]
    }()

    /// The dependency of this component.
    ///
    /// - note: Accessing this property is not thread-safe. It should only be
    /// accessed on the same thread as the one that instantiated this component.
    public private(set) var dependency: DependencyType!

    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public init(parent: Scope) {
        self.parent = parent
        dependency = createDependencyProvider()
    }

    /// Share the enclosed object as a singleton at this scope. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads
    /// as it may cause a deadlock.
    ///
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func shared<T>(__function: StaticString = #function, _ factory: () -> T) -> T {
        return shared(__function: __function, args: Nothing(), factory)
    }

    /// Share the enclosed object as a singleton at this scope based on the `args` parameter. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause a deadlock.
    ///
    /// - parameter args: A value that conforms to the `Hashable` protocol to differentiate between singleton instances.
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func shared<Args: Hashable, T>(__function: StaticString = #function, args: Args, _ factory: () -> T) -> T {
        sharedInstanceLock.lock()
        defer {
            sharedInstanceLock.unlock()
        }

        return storage.shared(function: __function, args: args, factory: factory)
    }

    /// Share the enclosed object as a weak singleton at this scope. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause a deadlock.
    ///
    /// - note: This function is only applicable for reference types (classes).
    ///
    /// - parameter args: A value that conforms to the `Hashable` protocol to differentiate between singleton instances.
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func weakShared<T: AnyObject>(__function: StaticString = #function, _ factory: () -> T) -> T {
        return weakShared(__function: __function, args: Nothing(), factory)
    }

    /// Share the enclosed object as a weak singleton at this scope based on the `args` parameter. This allows
    /// this scope as well as all child scopes to share a single instance of
    /// the object, for as long as this component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause a deadlock.
    ///
    /// - note: This function is only applicable for reference types (classes).
    ///
    /// - parameter args: A value that conforms to the `Hashable` protocol to differentiate between singleton instances.
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func weakShared<Args: Hashable, T: AnyObject>(__function: StaticString = #function, args: Args, _ factory: () -> T) -> T {
        sharedInstanceLock.lock()
        defer {
            sharedInstanceLock.unlock()
        }

        return storage.weakShared(function: __function, args: args, factory: factory)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<DependencyType, T>) -> T {
        return dependency[keyPath: keyPath]
    }

    // MARK: - Private

    private let sharedInstanceLock = NSRecursiveLock()
    private let storage = AssemblyStorage()
    private lazy var name: String = {
        let fullyQualifiedSelfName = String(describing: self)
        let parts = fullyQualifiedSelfName.components(separatedBy: ".")
        return parts.last ?? fullyQualifiedSelfName
    }()

    // TODO: Replace this with an `open` method, once Swift supports extension
    // overriding methods.
    private func createDependencyProvider() -> DependencyType {
        let provider = __DependencyProviderRegistry.instance.dependencyProvider(for: self)
        if let dependency = provider as? DependencyType {
            return dependency
        } else {
            // This case should never occur with properly generated Needle code.
            // Needle's official generator should guarantee the correctness.
            fatalError("Dependency provider factory for \(self) returned incorrect type. Should be of type \(String(describing: DependencyType.self)). Actual type is \(String(describing: dependency))")
        }
    }
}

#endif
