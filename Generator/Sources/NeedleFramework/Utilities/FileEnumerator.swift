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

/// A utility class that provides file enumeration from a root directory.
class FileEnumerator {

    /// Enumerate all the files in the root directory URL, recursively.
    ///
    /// - parameter rootUrl: The root directory URL to enumerate from.
    /// - parameter handler: The closure to invoke when a file URL is found.
    func enumerate(from rootUrl: URL, handler: (URL) -> Void) {
        let enumerator = newFileEnumerator(for: rootUrl)
        while let nextObjc = enumerator.nextObject() {
            if let fileUrl = nextObjc as? URL {
                handler(fileUrl)
            }
        }
    }

    // MARK: - Private

    private func newFileEnumerator(for rootUrl: URL) -> FileManager.DirectoryEnumerator {
        let errorHandler = { (url: URL, error: Error) -> Bool in
            fatalError("Failed to traverse \(url) with error \(error).")
        }
        if let enumerator = FileManager.default.enumerator(at: rootUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: errorHandler) {
            return enumerator
        } else {
            fatalError("\(rootUrl) does not exist.")
        }
    }
}
