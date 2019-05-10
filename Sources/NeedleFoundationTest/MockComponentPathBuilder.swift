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
import NeedleFoundation

/**
 This function allows you to get access to a mock component path builder that you can use to
 build mock component paths of type MockComponentPath. You can use these paths to register mock
 dependency providers during testing.
 */
public func mockComponentPathBuilder() -> MockComponentPathBuilder {
    return MockComponentPathBuilder(dependencyProviderRegistry:  __DependencyProviderRegistry.instance)
}

/**
 MockComponentPathBuilder aloows you to build a component path that mirrors the ancestry of a component.
 Once the path is created, you can invoke build to create an instance of MockComponentPath. This class is not
 intended to be subclassed.
 */
public final class MockComponentPathBuilder {
    private let dependencyProviderRegistry: __DependencyProviderRegistry
    private var path: [String] = ["^"]
    fileprivate init(dependencyProviderRegistry: __DependencyProviderRegistry) {
        self.dependencyProviderRegistry = dependencyProviderRegistry
    }
    
    /**
     Extend the component path from the leaf component in the current component path to its next child
     in the ancestry tree.
     */
    public func extendPath(to componentType: AnyClass) -> MockComponentPathBuilder {
        let nodeName: String
//        if componentType !== BootstrapComponent.self {
            let fullyQualifiedSelfName = String(describing: componentType)
            let parts = fullyQualifiedSelfName.components(separatedBy: ".")
            nodeName = parts.last ?? fullyQualifiedSelfName
//        } else {
//            nodeName = "^"
//        }
        path.append(nodeName)
        return self
    }
    
    /**
     Build the mock component path based.
     */
    public func build() -> MockComponentPath {
        return MockComponentPath(path: pathString(), dependencyProviderRegistry: dependencyProviderRegistry)
    }
    
    private func pathString() -> String {
        return path.joined(separator: "->")
    }
}

/**
 This class represents the mocked component path that describes the ancestory of a component.
 This can be used to register a mock dependency provider for the component. This class is not
 intended to be subclassed.
 */
public final class MockComponentPath {
    private let path: String
    private let dependencyProviderRegistry: __DependencyProviderRegistry
    private var preexistingDependencyProviderFactory: ((Scope) -> AnyObject)? = nil
    fileprivate init(path: String, dependencyProviderRegistry: __DependencyProviderRegistry) {
        self.path = path
        self.dependencyProviderRegistry = dependencyProviderRegistry
    }
    
    /**
     Register a dependency provider for the mocked component path.
     - Parameter dependencyProvider: The dependency provider to handle dependencies for the component.
     */
    public func register(dependencyProvider: AnyObject) {
        preexistingDependencyProviderFactory = dependencyProviderRegistry.dependencyProviderFactory(for: path)
        dependencyProviderRegistry.registerDependencyProviderFactory(for: path) { _ in
            return dependencyProvider
        }
    }
    
    /**
     Unregister a previously registered dependency provider for the mocked component path.
     */
    public func unregister() {
        dependencyProviderRegistry.unregisterDependencyProviderFactory(for: path)
        if let preexistingDependencyProviderFactory = preexistingDependencyProviderFactory {
            dependencyProviderRegistry.registerDependencyProviderFactory(for: path, preexistingDependencyProviderFactory)
        }
    }
}
