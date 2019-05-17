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
@testable import NeedleFoundationTest

class MockComponentPathBuilderTests: XCTestCase {
    class TestComponent2: TestComponent {}
    class TestComponent3: TestComponent {}
    class MockDependencyProvider: EmptyDependency {}
    let mockBootstrapDependencyProvider = MockDependencyProvider()
    let mockBootstrapComponentPath = mockComponentPathBuilder()
        .extendPath(to: BootstrapComponent.self)
        .build()

    override func setUp() {
        super.setUp()
        mockBootstrapComponentPath.register(dependencyProvider: mockBootstrapDependencyProvider)
    }
    
    override func tearDown() {
        super.tearDown()
        mockBootstrapComponentPath.unregister()
    }

    func test_componentPathBuilder_verifyRegistration() {
        let testDependencyProvider = MockDependencyProvider()
        let componentPath = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .build()
        componentPath.register(dependencyProvider: testDependencyProvider)
        defer {
            componentPath.unregister()
        }
        
        let bootstrapComponent = BootstrapComponent()
        let testComponent = TestComponent(parent: bootstrapComponent)
        let retrievedDependencyProvider = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent)
        XCTAssert(testDependencyProvider === retrievedDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider))")
    }
    
    func test_componentPathBuilder_withLongerComponentPath_verifyRegistration() {
        let testDependencyProvider = MockDependencyProvider()
        let componentPath1 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .build()
        componentPath1.register(dependencyProvider: testDependencyProvider)
        let componentPath2 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .extendPath(to: TestComponent2.self)
            .build()
        componentPath2.register(dependencyProvider: testDependencyProvider)
        let componentPath3 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .extendPath(to: TestComponent2.self)
            .extendPath(to: TestComponent3.self)
            .build()
        componentPath3.register(dependencyProvider: testDependencyProvider)
        defer {
            componentPath1.unregister()
            componentPath2.unregister()
            componentPath3.unregister()
        }
        
        let bootstrapComponent = BootstrapComponent()
        let testComponent1 = TestComponent(parent: bootstrapComponent)
        let testComponent2 = TestComponent2(parent: testComponent1)
        let testComponent3 = TestComponent3(parent: testComponent2)
        let retrievedDependencyProvider1 = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent1)
        let retrievedDependencyProvider2 = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent2)
        let retrievedDependencyProvider3 = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent3)
        XCTAssert(retrievedDependencyProvider1 === testDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider1))")
        XCTAssert(retrievedDependencyProvider2 === testDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider2))")
        XCTAssert(retrievedDependencyProvider3 === testDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider3))")
    }
    
    func test_componentPathBuilder_unregister_verifyDependencyProvidersIsUnregistered() {
        let testDependencyProvider = MockDependencyProvider()
        let componentPath1 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .build()
        componentPath1.register(dependencyProvider: testDependencyProvider)
        let componentPath2 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .extendPath(to: TestComponent2.self)
            .build()
        componentPath2.register(dependencyProvider: testDependencyProvider)
        
        let bootstrapComponent = BootstrapComponent()
        let testComponent1 = TestComponent(parent: bootstrapComponent)
        let testComponent2 = TestComponent2(parent: testComponent1)
        
        let retrievedDependencyProvider = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent2)
        XCTAssert(testDependencyProvider === retrievedDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider))")
        
        let dependencyProviderRegistry = __DependencyProviderRegistry.instance
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent->TestComponent2"), "We should get back the right dependency provider after invoking unregister")
        // Unregistering the dependency provider for a component that DID NOT HAVE a pre-existing dependency provider
        componentPath2.unregister()
        XCTAssertNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent->TestComponent2"), "We should not get back the right dependency provider after invoking unregister")
    }

    func test_componentPathBuilder_unregister_verifyFallbackToPreviouslyRegisteredDependencyProvider() {
        // Add a dependency provider for a path the old way
        let path = "^->TestComponent"
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: path) { component in
            return EmptyDependencyProvider.init(component: component)
        }
        let testDependencyProvider = MockDependencyProvider()
        let componentPath1 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .build()
        componentPath1.register(dependencyProvider: testDependencyProvider)
        
        let bootstrapComponent = BootstrapComponent()
        let testComponent1 = TestComponent(parent: bootstrapComponent)
        
        let retrievedDependencyProvider = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent1)
        XCTAssert(testDependencyProvider === retrievedDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider))")
        
        let dependencyProviderRegistry = __DependencyProviderRegistry.instance
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent"), "We should get back the right dependency provider before invoking unregister")
        // Unregistering the dependency provider for a component that HAD a pre-existing dependency provider
        componentPath1.unregister()
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent"), "We should get back the pre-exisitng dependency provider")
        // Attempting to unregister the dependency provider for a component that had already been unregistered should
        // not remove the pre-existing dependency provider.
        componentPath1.unregister()
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent"), "We should get back the pre-exisitng dependency provider")
    }

    func test_componentPathBuilder_unregister_verifyDoesNotUnregisterPrexistingDependencyProvider() {
        // Add a dependency provider for a path the old way.
        let path = "^->TestComponent"
        // Register a dependency provider that will be treated as the pre-existing dependency provider.
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: path) { component in
            return EmptyDependencyProvider.init(component: component)
        }
        let testDependencyProvider = MockDependencyProvider()
        let componentPath1 = mockComponentPathBuilder()
            .extendPath(to: BootstrapComponent.self)
            .extendPath(to: TestComponent.self)
            .build()
        componentPath1.register(dependencyProvider: testDependencyProvider)
        
        let bootstrapComponent = BootstrapComponent()
        let testComponent1 = TestComponent(parent: bootstrapComponent)
        
        let retrievedDependencyProvider = __DependencyProviderRegistry.instance.dependencyProvider(for: testComponent1)
        XCTAssert(testDependencyProvider === retrievedDependencyProvider, "\nexpected: \(String(describing: testDependencyProvider))\ngot this:- \(String(describing: retrievedDependencyProvider))")
        
        let dependencyProviderRegistry = __DependencyProviderRegistry.instance
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent"), "We should get back the right dependency provider before invoking unregister")
        // Unregistering the dependency provider for a component that HAD a pre-existing dependency provider
        componentPath1.unregister()
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent"), "We should get back the pre-exisitng dependency provider")
        // Attempting to unregister the dependency provider for a component that had already been unregistered should
        // not remove the pre-existing dependency provider.
        componentPath1.unregister()
        XCTAssertNotNil(dependencyProviderRegistry.dependencyProviderFactory(for: "^->BootstrapComponent->TestComponent"), "We should get back the pre-exisitng dependency provider")
    }
}

class TestComponent: Component<EmptyDependency> {
    
    fileprivate var callCount: Int = 0
    fileprivate var expectedOptionalShare: ClassProtocol? = {
        return ClassProtocolImpl()
    }()
    
    var share: NSObject {
        callCount += 1
        return shared { NSObject() }
    }
    
    var share2: NSObject {
        return shared { NSObject() }
    }
    
    fileprivate var optionalShare: ClassProtocol? {
        return shared { self.expectedOptionalShare }
    }
}

private protocol ClassProtocol: AnyObject {
    
}

private class ClassProtocolImpl: ClassProtocol {
    
}
