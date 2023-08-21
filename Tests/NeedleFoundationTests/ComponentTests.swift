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

class ComponentTests: XCTestCase {

    override func setUp() {
        super.setUp()

        let path = "^->TestComponent"
        __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: path) { component in
            return EmptyDependencyProvider.init(component: component)
        }
    }

    func test_shared_veirfySingleInstance() {
        let component = TestComponent()
        XCTAssert(component.share === component.share, "Should have returned same shared object")

        XCTAssertTrue(component.share2 === component.share2)
        XCTAssertFalse(component.share === component.share2)
    }

    func test_shared_optional() {
        let component = TestComponent()
        XCTAssert(component.optionalShare === component.expectedOptionalShare)
    }

    func test_sharedWithArgs_verifySingleInstance() {
        let component = TestComponent()
        let args = "args"
        XCTAssert(component.share(args: args) === component.share(args: args), "Should have returned same shared object")
    }

    func test_sharedWithArgs_verifyDifferentInstancePerArgs() {
        let component = TestComponent()
        let args1 = "args1"
        let args2 = "args2"
        XCTAssert(component.share(args: args1) !== component.share(args: args2), "Should have returned different shared object")
    }

    func test_weakShared_verifySingleInstance() {
        let component = TestComponent()
        let weakShare1 = component.weakShare
        let weakShare2 = component.weakShare
        XCTAssert(weakShare1 === weakShare2, "Should have returned same shared object")
    }

    func test_weakReferenceOfWeakShared_deallocated() {
        let component = TestComponent()
        weak var weakShare = component.weakShare
        XCTAssert(weakShare == nil, "Should have been deallocated without a strong reference")
    }

    func test_weakSharedWithSameArgs_verifySingleInstance() {
        let component = TestComponent()
        let args = "args"
        let weakShare1 = component.weakShare(args: args)
        let weakShare2 = component.weakShare(args: args)
        XCTAssert(weakShare1 === weakShare2, "Should have returned same shared object")
    }

    func test_weakSharedWithDifferentArgs_verifyDifferentInstance() {
        let component = TestComponent()
        let args1 = "args1"
        let args2 = "args2"
        let weakShare1 = component.weakShare(args: args1)
        let weakShare2 = component.weakShare(args: args2)
        XCTAssert(weakShare1 !== weakShare2, "Should have been different with different arguments")
    }
}

class TestComponent: BootstrapComponent {

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

    func share<Arg: Hashable>(args: Arg) -> NSObject {
        return shared(args: args) { NSObject() }
    }

    var weakShare: NSObject {
        return weakShared { NSObject() }
    }

    func weakShare<Arg: Hashable>(args: Arg) -> NSObject {
        return weakShared(args: args) { NSObject() }
    }
}

private protocol ClassProtocol: AnyObject {

}

private class ClassProtocolImpl: ClassProtocol {

}
