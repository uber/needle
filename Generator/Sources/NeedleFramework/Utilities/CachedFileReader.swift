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

/// A singleton utility providing file content reading functionality
/// with caching built-in.
class CachedFileReader {

    /// The singleton instance.
    static let instance = CachedFileReader()

    /// Retrieve the content at the given URL.
    ///
    /// - note: If the URL file content has been read into memory already,
    /// the cached data is returned. Otherwise the file is read from disk.
    /// - parameter url: The URL to read the file from.
    /// - returns: The file content at the given URL.
    /// - throws: If reading file failed.
    func content(forUrl url: URL) throws -> String {
        let nsUrl = url as NSURL
        if let cachedContent = cache.object(forKey: nsUrl) {
            return cachedContent as String
        }

        let content = try String(contentsOf: url)
        cache.setObject(content as NSString, forKey: nsUrl)
        return content
    }

    // MARK: - Private

    private let cache = NSCache<NSURL, NSString>()

    private init() {}
}
