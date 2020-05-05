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

import XCTest
@testable import NeedleFramework

class DependencyProviderSerializerTaskTests: AbstractGeneratorTests {

    func test_execute_withSampleProject_verifySerialization() {
        let (components, imports) = sampleProjectParsed()
        for component in components {
            let providers = DependencyProviderDeclarerTask(component: component).execute()
            let processedProviders = try! DependencyProviderContentTask(providers: providers).execute()
            for provider in processedProviders {
                let serializedProviders = DependencyProviderSerializerTask(providers: [provider]).execute()
                XCTAssert(serializedProviders.count > 0 && serializedProviders.count < 3)
                verify(provider, against: serializedProviders)
            }
        }

        XCTAssertEqual(imports, ["import NeedleFoundation", "import RxSwift", "import UIKit"])
    }

    private func verify(_ provider: ProcessedDependencyProvider, against serializedProviders: [SerializedProvider]) {
        switch provider.unprocessed.pathString {
        case "^->RootComponent->LoggedInComponent->GameComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->RootComponent->LoggedInComponent->GameComponent") { component in
    return GameDependency1ab5926a977f706d3195Provider(component: component)
}

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedInComponent->GameComponent
private class GameDependency1ab5926a977f706d3195Provider: GameDependency1ab5926a977f706d3195BaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(loggedInComponent: component.parent as! LoggedInComponent, rootComponent: component.parent.parent as! RootComponent)
    }
}

""")
        case "^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent\") { component in
    return ScoreSheetDependency97f2595a691a56781aaaProvider(component: component)
}

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedInComponent->GameComponent->ScoreSheetComponent
private class ScoreSheetDependency97f2595a691a56781aaaProvider: ScoreSheetDependency97f2595a691a56781aaaBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(loggedInComponent: component.parent.parent as! LoggedInComponent)
    }
}

""")
        case "^->RootComponent->LoggedInComponent->ScoreSheetComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent->ScoreSheetComponent\") { component in
    return ScoreSheetDependencycbd7fa4bae2ee69a1926Provider(component: component)
}

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedInComponent->ScoreSheetComponent
private class ScoreSheetDependencycbd7fa4bae2ee69a1926Provider: ScoreSheetDependencycbd7fa4bae2ee69a1926BaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(loggedInComponent: component.parent as! LoggedInComponent)
    }
}

""")
        case "^->RootComponent->LoggedOutComponent":
            XCTAssertEqual(serializedProviders[1].registration, """
__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedOutComponent\") { component in
    return LoggedOutDependencyacada53ea78d270efa2fProvider(component: component)
}

""")
            XCTAssertEqual(serializedProviders[1].content, """
/// ^->RootComponent->LoggedOutComponent
private class LoggedOutDependencyacada53ea78d270efa2fProvider: LoggedOutDependencyacada53ea78d270efa2fBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(rootComponent: component.parent as! RootComponent)
    }
}

""")
        case "^->RootComponent->LoggedInComponent":
            XCTAssertEqual(serializedProviders[0].registration, """
__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent->LoggedInComponent\") { component in
    return EmptyDependencyProvider(component: component)
}

""")
        case "^->RootComponent":
            XCTAssertEqual(serializedProviders[0].registration, """
__DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: \"^->RootComponent\") { component in
    return EmptyDependencyProvider(component: component)
}

""")
        default:
            XCTFail("Unverified provider with path \(provider.unprocessed.pathString)")
        }
    }
}
