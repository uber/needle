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

import Concurrency
import XCTest
@testable import NeedleFramework

class AbstractPluginizedGeneratorTests: XCTestCase {

    /// Retrieve the parsed component data models and import statements
    /// for the sample project.
    ///
    /// - returns: The list of component data models, pluginized component
    /// data models and sorted import statements.
    func pluginizedSampleProjectParsed() -> ([Component], [PluginizedComponent], [String], String) {
        let parser = PluginizedDependencyGraphParser()
        let fixturesURL = sampleProjectUrl()
        let executor = MockSequenceExecutor()

        do {
            return try parser.parse(from: [fixturesURL], withSourcesListFormat: nil, excludingFilesEndingWith: ["ha", "yay", "blah"], using: executor, withTimeout: 10)
        } catch {
            fatalError("\(error)")
        }
    }

    /// Retrieve the URL for the sample project folder.
    ///
    /// - returns: The sample project folder URL.
    func sampleProjectUrl() -> URL {
        var url = URL(fileURLWithPath: #file)
        for _ in 0 ..< 6 {
            url = url.deletingLastPathComponent()
        }
        url.appendPathComponent("Sample/Pluginized/TicTacToe/")

        let path = url.absoluteString.replacingOccurrences(of: "file://", with: "")
        return URL(path: path)
    }
}
