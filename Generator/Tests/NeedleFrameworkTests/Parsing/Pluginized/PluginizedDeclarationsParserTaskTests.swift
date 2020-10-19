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
@testable import NeedleFramework
import SwiftSyntax

class PluginizedDeclarationsParserTaskTests: AbstractParserTests {

    func test_execute_withValidAndInvalidComponentsDependencies_verifyPluginizedDependencyGraphNode() {
        let sourceUrl = fixtureUrl(for: "ComponentSample.swift")
        let sourceContent = try! String(contentsOf: sourceUrl)
        let imports = ["import UIKit", "import RIBs", "import Foundation"]
        let ast = AST(sourceHash: MD5(string: sourceContent),
                      sourceFileSyntax: try! SyntaxParser.parse(sourceUrl))

        let task = PluginizedDeclarationsParserTask(ast: ast)
        let node = try! task.execute()
        
        // Imports
        for statement in imports {
            XCTAssertTrue(node.imports.contains(statement))
        }

        // Regular components.
        XCTAssertEqual(node.components.count, 3)
        let myComponent = node.components.first { (component: ASTComponent) -> Bool in
            component.name == "MyComponent"
        }!
        XCTAssertEqual(myComponent.expressionCallTypeNames, ["Basket", "Donut", "MyChildComponent", "Stream", "shared"])
        XCTAssertEqual(myComponent.name, "MyComponent")
        XCTAssertEqual(myComponent.dependencyProtocolName, "MyDependency")
        XCTAssertEqual(myComponent.properties.count, 4)
        let containsStream = myComponent.properties.contains { (property: Property) -> Bool in
            return property.name == "stream" && property.type == "Stream"
        }
        XCTAssertTrue(containsStream)
        let containsDonut = myComponent.properties.contains { (property: Property) -> Bool in
            return property.name == "donut" && property.type == "Donut"
        }
        XCTAssertTrue(containsDonut)
        let containsBasket = myComponent.properties.contains { (property: Property) -> Bool in
            return property.name == "sweetsBasket" && property.type == "Basket"
        }
        XCTAssertTrue(containsBasket)
        let containsChildComponent = myComponent.properties.contains { (property: Property) -> Bool in
            return property.name == "myChildComponent" && property.type == "MyChildComponent"
        }
        XCTAssertTrue(containsChildComponent)

        let my2Component = node.components.first { (component: ASTComponent) -> Bool in
            component.name == "My2Component"
        }!
        XCTAssertEqual(my2Component.expressionCallTypeNames, ["Apple", "Banana", "Book", "MyStorage", "Wallet", "shared"])
        XCTAssertEqual(my2Component.name, "My2Component")
        XCTAssertEqual(my2Component.dependencyProtocolName, "My2Dependency")
        XCTAssertEqual(my2Component.properties.count, 3)
        let containsBook = my2Component.properties.contains { (property: Property) -> Bool in
            return property.name == "book" && property.type == "Book"
        }
        XCTAssertTrue(containsBook)
        let containsOptionalWallet = my2Component.properties.contains { (property: Property) -> Bool in
            return property.name == "maybeWallet" && property.type == "Wallet?"
        }
        XCTAssertTrue(containsOptionalWallet)

        let myRComp = node.components.first { (component: ASTComponent) -> Bool in
            component.name == "MyRComp"
            }!
        XCTAssertEqual(myRComp.expressionCallTypeNames, ["Obj", "shared"])
        XCTAssertEqual(myRComp.name, "MyRComp")
        XCTAssertEqual(myRComp.dependencyProtocolName, "EmptyDependency")
        XCTAssertTrue(myRComp.isRoot)
        XCTAssertEqual(myRComp.properties.count, 1)
        XCTAssertEqual(myRComp.properties, [Property(name: "rootObj", type: "Obj")])

        // Non-core components.
        XCTAssertEqual(node.nonCoreComponents.count, 1)
        let someNonCoreComponent = node.nonCoreComponents.first { (component: ASTComponent) -> Bool in
            component.name == "SomeNonCoreComponent"
        }!
        XCTAssertEqual(someNonCoreComponent.expressionCallTypeNames, ["NonCoreObject", "SharedObject", "shared"])
        XCTAssertEqual(someNonCoreComponent.name, "SomeNonCoreComponent")
        XCTAssertEqual(someNonCoreComponent.dependencyProtocolName, "SomeNonCoreDependency")
        XCTAssertEqual(someNonCoreComponent.properties.count, 2)
        let containsNewNonCoreObject = someNonCoreComponent.properties.contains { (property: Property) -> Bool in
            return property.name == "newNonCoreObject" && property.type == "NonCoreObject?"
        }
        XCTAssertTrue(containsNewNonCoreObject)
        let containsSharedNonCoreObject = someNonCoreComponent.properties.contains { (property: Property) -> Bool in
            return property.name == "sharedNonCoreObject" && property.type == "SharedObject"
        }
        XCTAssertTrue(containsSharedNonCoreObject)

        // Pluginized components.
        XCTAssertEqual(node.pluginizedComponents.count, 1)
        let somePluginizedCompo = node.pluginizedComponents.first { (component: PluginizedASTComponent) -> Bool in
            component.data.name == "SomePluginizedComp"
        }!
        XCTAssertEqual(somePluginizedCompo.data.expressionCallTypeNames, ["LGOLEDTv"])
        XCTAssertEqual(somePluginizedCompo.data.name, "SomePluginizedComp")
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

        // Plugin extensions.
        XCTAssertEqual(node.pluginExtensions.count, 1)
        let bExtension = node.pluginExtensions.first { (pluginExtension: PluginExtension) -> Bool in
            pluginExtension.name == "BExtension"
        }!
        XCTAssertEqual(bExtension.name, "BExtension")
        XCTAssertEqual(bExtension.properties.count, 1)
        let containsMyPluginPoint = bExtension.properties.contains { (property: Property) -> Bool in
            property.name == "myPluginPoint"
        }
        XCTAssertTrue(containsMyPluginPoint)
    }
}
