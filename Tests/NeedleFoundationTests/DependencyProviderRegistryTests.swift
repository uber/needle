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

import XCTest
@testable import NeedleFoundation

class DependencyProviderRegistryTests: XCTestCase {

    override func setUp() {
        super.setUp()

        let path = "^->MockAppComponent"
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: path) { component in
            return EmptyDependencyProvider(component: component)
        }
    }

    func test_registerProviderFactory_verifyRetrievingProvider_verifyDependencyReference() {
        let expectedProvider = MockRootDependencyProvider()

        let path = "^->MockAppComponent->MockRootComponent"
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: path) { (component: Scope) -> AnyObject in
            return expectedProvider
        }

        let appComponent = MockAppComponent()
        let actualProvider = __DependencyProviderRegistry.instance.dependencyProvider(for: appComponent.rootComponent)

        XCTAssertTrue(expectedProvider === actualProvider)
        XCTAssertTrue(appComponent.rootComponent.dependency === expectedProvider)
    }
}

class MockAppComponent: BootstrapComponent {

    var rootComponent: MockRootComponent {
        return MockRootComponent(parent: self)
    }
}

protocol MockRootDependency: AnyObject {}

class MockRootComponent: Component<MockRootDependency> {}

class MockRootDependencyProvider: MockRootDependency {}
