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

public class DirectoryScanner {
    private let directoryURL: URL
    private let suffixesToSkip: [String]?

    public init(path: String, withoutSuffixes suffixes: [String]?) {
        directoryURL = URL(fileURLWithPath: path)
        suffixesToSkip = suffixes
    }

    private func shouldConsider(url: URL?) -> URL? {
        guard let url = url, url.pathExtension == "swift" else { return nil }

        if let suffixes = suffixesToSkip {
            let name = url.deletingPathExtension().lastPathComponent
            for suffix in suffixes {
                if name.hasSuffix(suffix) {
                    return nil
                }
            }
        }

        return url
    }

    public func scan(process: (URL) -> ()) {
        let errorHandler: (URL, Error) -> Bool = { (url, error) -> Bool in
            print("Directory traversal error at \(url): ", error)
            return true
        }
        guard let enumerator = FileManager.default.enumerator(at: directoryURL,
                                                              includingPropertiesForKeys: nil,
                                                              options: [.skipsHiddenFiles],
                                                              errorHandler: errorHandler) else { return }

        while let next = enumerator.nextObject() {
            if let url = shouldConsider(url: next as? URL) {
                process(url)
            }
        }
    }
}
