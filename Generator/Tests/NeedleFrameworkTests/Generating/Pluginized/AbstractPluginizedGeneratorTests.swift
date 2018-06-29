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

class AbstractPluginizedGeneratorTests: XCTestCase {

    /// Retrieve the parsed component data models and import statements
    /// for the sample project.
    ///
    /// - returns: The list of component data models, pluginized component
    /// data models and sorted import statements.
    func pluginizedSampleProjectParsed() -> ([Component], [PluginizedComponent], [String]) {
        let parser = PluginizedDependencyGraphParser()
        let fixturesURL = sampleProjectUrl()
        let executor = MockSequenceExecutor()

        do {
            return try parser.parse(from: fixturesURL, excludingFilesWithSuffixes: ["ha", "yay", "blah"], using: executor)
        } catch {
            fatalError("\(error)")
        }
    }

    /// Retrieve the URL for the sample project folder.
    ///
    /// - returns: The sample project folder URL.
    func sampleProjectUrl() -> URL {
        var dir = URL(fileURLWithPath: #file)
        for _ in 0 ..< 6 {
            dir = dir.deletingLastPathComponent()
        }
        dir.appendPathComponent("Sample/Pluginized/TicTacToe/")
        return dir
    }

    func test() {
        let (components, pluginizedComponents, _) = pluginizedSampleProjectParsed()
        var allProviders = [DependencyProvider]()
        for component in components {
            let task = DependencyProviderDeclarerTask(component: component)
            allProviders.append(contentsOf: task.execute())
        }
        for component in pluginizedComponents {
            let task = DependencyProviderDeclarerTask(component: component.data)
            allProviders.append(contentsOf: task.execute())
        }

        for provider in allProviders {
            print(provider.pathString)
        }

        let task = PluginizedDependencyProviderContentTask(providers: allProviders, pluginizedComponents: pluginizedComponents)
        task.execute()
    }
}
