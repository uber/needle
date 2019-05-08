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

class PluginizedComponentTests: XCTestCase {

    override func setUp() {
        super.setUp()

        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->BootstrapComponent") { component in
            return EmptyDependencyProvider(component: component)
        }

        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->BootstrapComponent->MockPluginizedComponent") { component in
            return EmptyDependencyProvider(component: component)
        }

        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->BootstrapComponent->MockPluginizedComponent->MockNonCoreComponent") { component in
            return EmptyDependencyProvider(component: component)
        }

        __PluginExtensionProviderRegistry.instance.registerPluginExtensionProviderFactory(for: "MockPluginizedComponent") { pluginizedComponent in
            return EmptyPluginExtensionsProvider()
        }
    }

    func test_nonCoreComponent_pluginExtensions_verifyTypes() {
        let mockPluginizedComponent = MockPluginizedComponent()

        XCTAssertTrue(mockPluginizedComponent.nonCoreComponent is MockNonCoreComponent)
        XCTAssertTrue(mockPluginizedComponent.pluginExtension is EmptyPluginExtensionsProvider)
    }

    func test_bindTo_verifyNonCoreComponentLifecycle() {
        let mockPluginizedComponent = MockPluginizedComponent()
        let mockDisposable = MockObserverDisposable()
        let mockLifecycle = MockPluginizedScopeLifecycleObervable(disposable: mockDisposable)
        let noncoreComponent: MockNonCoreComponent? = mockPluginizedComponent.nonCoreComponent as? MockNonCoreComponent
        mockPluginizedComponent.bind(to: mockLifecycle)

        XCTAssertEqual(noncoreComponent!.scopeDidBecomeActiveCallCount, 0)
        XCTAssertEqual(noncoreComponent!.scopeDidBecomeInactiveCallCount, 0)

        mockLifecycle.observer!(.active)

        XCTAssertEqual(noncoreComponent!.scopeDidBecomeActiveCallCount, 1)
        XCTAssertEqual(noncoreComponent!.scopeDidBecomeInactiveCallCount, 0)

        mockLifecycle.observer!(.inactive)

        XCTAssertEqual(noncoreComponent!.scopeDidBecomeActiveCallCount, 1)
        XCTAssertEqual(noncoreComponent!.scopeDidBecomeInactiveCallCount, 1)
    }

    func test_bindTo_verifyReleasingNonCoreComponent() {
        let mockPluginizedComponent = MockPluginizedComponent()
        var noncoreComponent: MockNonCoreComponent? = mockPluginizedComponent.nonCoreComponent as? MockNonCoreComponent
        var noncoreDeinitCallCount = 0
        noncoreComponent!.deinitHandler = {
            noncoreDeinitCallCount += 1
        }
        let mockDisposable = MockObserverDisposable()
        let mockLifecycle = MockPluginizedScopeLifecycleObervable(disposable: mockDisposable)
        mockPluginizedComponent.bind(to: mockLifecycle)

        XCTAssertNotNil(noncoreComponent)
        XCTAssertEqual(noncoreDeinitCallCount, 0)

        noncoreComponent = nil

        XCTAssertNil(noncoreComponent)
        XCTAssertEqual(noncoreDeinitCallCount, 0)

        mockLifecycle.observer!(.deinit)

        XCTAssertNil(noncoreComponent)
        XCTAssertEqual(noncoreDeinitCallCount, 1)

        XCTAssertNil(noncoreComponent)
        XCTAssertEqual(noncoreDeinitCallCount, 1)
    }
}

class MockNonCoreComponent: NonCoreComponent<EmptyDependency> {

    var deinitHandler: (() -> Void)?

    var scopeDidBecomeActiveCallCount = 0
    var scopeDidBecomeInactiveCallCount = 0

    override func scopeDidBecomeActive() {
        scopeDidBecomeActiveCallCount += 1
    }

    override func scopeDidBecomeInactive() {
        scopeDidBecomeInactiveCallCount += 1
    }

    deinit {
        deinitHandler?()
    }
}

protocol EmptyPluginExtensions {}

class EmptyPluginExtensionsProvider: EmptyPluginExtensions {}

class MockPluginizedComponent: PluginizedComponent<EmptyDependency, EmptyPluginExtensions, MockNonCoreComponent> {

    init() {
        super.init(parent: BootstrapComponent())
    }
}

class MockPluginizedScopeLifecycleObervable: PluginizedScopeLifecycleObservable {

    let disposable: ObserverDisposable

    init(disposable: ObserverDisposable) {
        self.disposable = disposable
    }

    var observer: ((PluginizedScopeLifecycle) -> Void)?

    func observe(_ observer: @escaping (PluginizedScopeLifecycle) -> Void) -> ObserverDisposable {
        self.observer = observer
        return disposable
    }
}

class MockObserverDisposable: ObserverDisposable {

    var disposeCallCount = 0

    func dispose() {
        disposeCallCount += 1
    }
}
