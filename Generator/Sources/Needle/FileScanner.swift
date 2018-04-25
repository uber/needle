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
    private let directoryURL: URL

    init(path: String) {
        directoryURL = URL(fileURLWithPath: path)
    }

    func scan() -> [URL] {
        let errorHandler: (URL, Error) -> Bool = { (url, error) -> Bool in
            print("Directory traversal error at \(url): ", error)
            return true
        }
        if let enumerator = FileManager.default.enumerator(at: directoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles],
                                                           errorHandler: errorHandler) {
            return enumerator.allObjects.flatMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        }
        return []
    }
}
