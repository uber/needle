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
import SourceKittenFramework

class FileScanner {
    private let filePath: String
    private let componentString = "Component"
    private let componentExpression = RegEx("Component *<")

    init(url: URL) {
        filePath = url.path
    }

    func scan() -> Structure? {
        guard let file = File(path: filePath) else {
            return nil
        }

        let simpleContains =  file.contents.contains(componentString)
        guard simpleContains else {
            return nil
        }

        let properContains = (componentExpression.firstMatch(file.contents) != nil)
        guard properContains else {
            return nil
        }

        let result = try? Structure(file: file)

        return result
    }
}
