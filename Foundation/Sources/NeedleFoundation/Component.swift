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

/// The base protocol of a component. Application code should inherit from the `Component`
/// base class, instead of using this protocol directly.
public protocol ComponentType: AnyObject {
    /// The path to reach this component on the dependnecy graph.
    var path: [String] { get }

    /// The parent of this component.
    // This property cannot be of `ComponentType`, since the root of the dependency graph
    // must have a parent that does not have a parent.
    var parent: ComponentType { get }
}

/// The base implementation of a dependency injection component. A subclass defines a unique
/// scope within the dependency injection tree, that contains a set of properties it provides
/// to units of its scope as well as child scopes. A component instantiates child components
/// that define child scopes.
open class Component<DependencyType>: ComponentType {

    /// The parent of this component.
    public let parent: ComponentType

    /// The path to reach this scope on the dependnecy graph.
    // Use `lazy var` to avoid computing the path repeatedly. Internally, this is always
    // accessed with the `__DependencyProviderRegistry`'s lock acquired.
    public lazy var path: [String] = {
        let name = self.name
        return parent.path + ["\(name)"]
    }()

    /// The dependency of this component.
    ///
    /// - note: Accessing this property is not thread-safe. It should only be accessed on the
    /// same thread as the one that instantiated this component.
    public private(set) var dependency: DependencyType!

    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public init(parent: ComponentType) {
        self.parent = parent
        dependency = createDependencyProvider()
    }

    /// Share the enclosed object as a singleton at this scope. This allows this scope as well
    /// as all child scopes to share a single instance of the object, for as long as this
    /// component lives.
    ///
    /// - note: Shared dependency's constructor should avoid switching threads as it may cause
    /// a deadlock.
    ///
    /// - parameter factory: The closure to construct the dependency object.
    /// - returns: The dependency object instance.
    public final func shared<T>(__function: String = #function, _ factory: () -> T) -> T {
        // Use function name as the key, since this is unique per component class. At the same time,
        // this is also 150 times faster than interpolating the type to convert to string, `"\(T.self)"`.
        sharedInstanceLock.lock()
        defer {
            sharedInstanceLock.unlock()
        }

        if let instance = sharedInstances[__function] as? T {
            return instance
        }
        let instance = factory()
        sharedInstances[__function] = instance

        return instance
    }

    // MARK: - Private

    private let sharedInstanceLock = NSRecursiveLock()
    private var sharedInstances = [String: Any]()
    private lazy var name: String = {
        let fullyQualifiedSelfName = String(describing: self)
        let parts = fullyQualifiedSelfName.components(separatedBy: ".")
        return parts.last ?? fullyQualifiedSelfName
    }()

    // TODO: Replace this with an `open` method, once Swift supports extension overriding methods.
    private func createDependencyProvider() -> DependencyType {
        let provider = __DependencyProviderRegistry.instance.dependencyProvider(for: self)
        if let dependency = provider as? DependencyType {
            return dependency
        } else {
            fatalError("Dependency provider factory for \(self) returned incorrect type. Should be of type \(String(describing: DependencyType.self)). Actual type is \(String(describing: dependency))")
        }
    }
}
