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

import SourceKittenFramework
import XCTest
@testable import NeedleFramework

class PluginizableASTParserTaskTests: AbstractParserTests {

    static var allTests = [
        ("test_execute_withValidAndInvalidComponentsDependencies_verifyPluginizableDependencyGraphNode", test_execute_withValidAndInvalidComponentsDependencies_verifyPluginizableDependencyGraphNode),
    ]

    func test_execute_withValidAndInvalidComponentsDependencies_verifyPluginizableDependencyGraphNode() {
        let sourceUrl = fixtureUrl(for: "ComponentSample.swift")
        let sourceContent = try! String(contentsOf: sourceUrl)
        let structure = try! Structure(file: File(contents: sourceContent))
        let imports = ["import UIKit", "import RIBs", "import Foundation"]

        let task = PluginizableASTParserTask(ast: AST(structure: structure, imports: imports))
        let node = task.execute()

        XCTAssertEqual(node.components.count, 4)

        // Regular components.
        let myComponent = node.components.first { (component: PluginizableASTComponent) -> Bool in
            component.data.name == "MyComponent"
        }!
        XCTAssertEqual(myComponent.data.expressionCallTypeNames, ["Stream", "Donut", "shared", "MyChildComponent", "Basket"])
        XCTAssertEqual(myComponent.data.name, "MyComponent")
        XCTAssertEqual(myComponent.data.dependencyProtocolName, "MyDependency")
        XCTAssertEqual(myComponent.data.properties.count, 4)
        XCTAssertNil(myComponent.pluginExtensionType)
        XCTAssertNil(myComponent.nonCoreComponentType)
        let containsStream = myComponent.data.properties.contains { (property: Property) -> Bool in
            return property.name == "stream" && property.type == "Stream"
        }
        XCTAssertTrue(containsStream)
        let containsDonut = myComponent.data.properties.contains { (property: Property) -> Bool in
            return property.name == "donut" && property.type == "Donut"
        }
        XCTAssertTrue(containsDonut)
        let containsBasket = myComponent.data.properties.contains { (property: Property) -> Bool in
            return property.name == "sweetsBasket" && property.type == "Basket"
        }
        XCTAssertTrue(containsBasket)
        let containsChildComponent = myComponent.data.properties.contains { (property: Property) -> Bool in
            return property.name == "myChildComponent" && property.type == "MyChildComponent"
        }
        XCTAssertTrue(containsChildComponent)

        let my2Component = node.components.first { (component: PluginizableASTComponent) -> Bool in
            component.data.name == "My2Component"
        }!
        XCTAssertEqual(my2Component.data.expressionCallTypeNames, ["shared", "Wallet", "Banana", "Apple", "Book"])
        XCTAssertEqual(my2Component.data.name, "My2Component")
        XCTAssertEqual(my2Component.data.dependencyProtocolName, "My2Dependency")
        XCTAssertEqual(my2Component.data.properties.count, 2)
        XCTAssertNil(my2Component.pluginExtensionType)
        XCTAssertNil(my2Component.nonCoreComponentType)
        let containsBook = my2Component.data.properties.contains { (property: Property) -> Bool in
            return property.name == "book" && property.type == "Book"
        }
        XCTAssertTrue(containsBook)
        let containsOptionalWallet = my2Component.data.properties.contains { (property: Property) -> Bool in
            return property.name == "maybeWallet" && property.type == "Wallet?"
        }
        XCTAssertTrue(containsOptionalWallet)

        let someNonCoreComponent = node.components.first { (component: PluginizableASTComponent) -> Bool in
            component.data.name == "SomeNonCoreComponent"
            }!
        XCTAssertEqual(someNonCoreComponent.data.expressionCallTypeNames, ["NonCoreObject", "shared", "SharedObject"])
        XCTAssertEqual(someNonCoreComponent.data.name, "SomeNonCoreComponent")
        XCTAssertEqual(someNonCoreComponent.data.dependencyProtocolName, "SomeNonCoreDependency")
        XCTAssertEqual(someNonCoreComponent.data.properties.count, 2)
        XCTAssertNil(someNonCoreComponent.pluginExtensionType)
        XCTAssertNil(someNonCoreComponent.nonCoreComponentType)
        let containsNewNonCoreObject = someNonCoreComponent.data.properties.contains { (property: Property) -> Bool in
            return property.name == "newNonCoreObject" && property.type == "NonCoreObject?"
        }
        XCTAssertTrue(containsNewNonCoreObject)
        let containsSharedNonCoreObject = someNonCoreComponent.data.properties.contains { (property: Property) -> Bool in
            return property.name == "sharedNonCoreObject" && property.type == "SharedObject"
        }
        XCTAssertTrue(containsSharedNonCoreObject)

        // Pluginized components.
        let somePluginizedCompo = node.components.first { (component: PluginizableASTComponent) -> Bool in
            component.data.name == "SomePluginizedCompo"
        }!
        XCTAssertEqual(somePluginizedCompo.data.expressionCallTypeNames, ["LGOLEDTv"])
        XCTAssertEqual(somePluginizedCompo.data.name, "SomePluginizedCompo")
        XCTAssertEqual(somePluginizedCompo.data.dependencyProtocolName, "ADependency")
        XCTAssertEqual(somePluginizedCompo.data.properties.count, 1)
        XCTAssertEqual(somePluginizedCompo.pluginExtensionType, "BExtension")
        XCTAssertEqual(somePluginizedCompo.nonCoreComponentType, "SomeNonCoreComponent")
        let containsTv = somePluginizedCompo.data.properties.contains { (property: Property) -> Bool in
            return property.name == "tv" && property.type == "Tv"
        }
        XCTAssertTrue(containsTv)

        // Dependency protocols.
        XCTAssertEqual(node.dependencies.count, 4)
        let myDependency = node.dependencies.first { (dependency: Dependency) -> Bool in
            dependency.name == "MyDependency"
        }!
        XCTAssertEqual(myDependency.name, "MyDependency")
        XCTAssertEqual(myDependency.properties.count, 2)
        let containsCandy = myDependency.properties.contains { (property: Property) -> Bool in
            return property.name == "candy" && property.type == "Candy"
        }
        XCTAssertTrue(containsCandy)
        let containsCheese = myDependency.properties.contains { (property: Property) -> Bool in
            return property.name == "cheese" && property.type == "Cheese"
        }
        XCTAssertTrue(containsCheese)

        let my2Dependency = node.dependencies.first { (dependency: Dependency) -> Bool in
            dependency.name == "My2Dependency"
        }!
        XCTAssertEqual(my2Dependency.name, "My2Dependency")
        XCTAssertEqual(my2Dependency.properties.count, 2)
        let containsBackPack = my2Dependency.properties.contains { (property: Property) -> Bool in
            return property.name == "backPack" && property.type == "Pack"
        }
        XCTAssertTrue(containsBackPack)
        let containsOptionalMoney = my2Dependency.properties.contains { (property: Property) -> Bool in
            return property.name == "maybeMoney" && property.type == "Dollar?"
        }
        XCTAssertTrue(containsOptionalMoney)

        let someNonCoreDependency = node.dependencies.first { (dependency: Dependency) -> Bool in
            dependency.name == "SomeNonCoreDependency"
        }!
        XCTAssertEqual(someNonCoreDependency.name, "SomeNonCoreDependency")
        XCTAssertEqual(someNonCoreDependency.properties.count, 2)
        let containsANonCoreDep = someNonCoreDependency.properties.contains { (property: Property) -> Bool in
            return property.name == "aNonCoreDep" && property.type == "Dep"
        }
        XCTAssertTrue(containsANonCoreDep)
        let containsMaybeNonCoreDep = someNonCoreDependency.properties.contains { (property: Property) -> Bool in
            return property.name == "maybeNonCoreDep" && property.type == "MaybeDep?"
        }
        XCTAssertTrue(containsMaybeNonCoreDep)

        let aDependency = node.dependencies.first { (dependency: Dependency) -> Bool in
            dependency.name == "ADependency"
        }!
        XCTAssertEqual(aDependency.name, "ADependency")
        XCTAssertEqual(aDependency.properties.count, 1)
        let containsMaybe = aDependency.properties.contains { (property: Property) -> Bool in
            return property.name == "maybe" && property.type == "Maybe?"
        }
        XCTAssertTrue(containsMaybe)

        // Imports.
        XCTAssertEqual(node.imports, ["import UIKit", "import RIBs", "import Foundation"])
    }
}
