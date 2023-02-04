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

    func test_weak_veirfySingleInstance() {
        let component = TestComponent()

        let id1 = "id1"
        let id2 = "id2"

        var weak: TestClass? = component.weak(hash: id1)
        weak?.number = 0
        XCTAssert(weak === component.weak(hash: id1), "Should have returned same shared object")
        XCTAssert(component.weak(hash: id1).number == 0)
        XCTAssertFalse(component.weak(hash: id1) === component.weak(hash: id2))

        weak = nil
        weak = component.weak(hash: id1)
        XCTAssertNotNil(weak)
        XCTAssertNil(component.weak(hash: id1).number)
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

    fileprivate func weak(hash: String) -> TestClass {
        return weak(hash: hash) { TestClass() }
    }
}

private protocol ClassProtocol: AnyObject {

}

private class ClassProtocolImpl: ClassProtocol {

}

private class TestClass {
    var number: Int? = nil
}
