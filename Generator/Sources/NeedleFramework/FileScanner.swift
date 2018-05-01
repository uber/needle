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

class FileScanner {
    public var contents: String?

    private let filePath: String
    private let componentString = "Component"
    private let componentExpression = RegEx("Component *<")

    init(url: URL) {
        filePath = url.path
    }

    func shouldScan() -> Bool {
        contents = try? String(contentsOfFile: filePath, encoding: .utf8)
        guard let contents = contents else {
            fatalError("Unable to read contents of file at: \(filePath)")
        }

        let simpleContains =  contents.contains(componentString)
        guard simpleContains else {
            return false
        }

        let properContains = (componentExpression.firstMatch(contents) != nil)
        guard properContains else {
            return false
        }

        return true
    }
}
