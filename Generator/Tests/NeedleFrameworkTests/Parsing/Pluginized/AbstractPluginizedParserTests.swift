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

@testable import NeedleFramework
import XCTest

/// Base class for all pluginized parser related tests.
class AbstractPluginizedParserTests: AbstractParserTests {

    /// Retrieve the URL for a pluginized fixture file.
    ///
    /// - parameter file: The name of the file including extension.
    /// - returns: The fixture file URL.
    func pluginizedFixtureUrl(for file: String) -> URL {
        return URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Fixtures/Pluginized/\(file)")
    }

    /// Retrieve the directory URL for the fixture folder.
    ///
    /// - returns: The fixture directory URL.
    func pluginizedFixtureDirUrl() -> URL {
        let url = fixtureUrl(for: "")
        let path = url.absoluteString.replacingOccurrences(of: "file://", with: "")
        return URL(path: path)
    }
}
