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

/// Errors that can occur when parsing the properly formatted version
/// `String`.
enum VersionStringErrors: Error {
    /// If the original value is not in the format of `major.minor.patch`,
    /// where all components are numbers only.
    case invalidFormat
}

extension String {

    /// Convert this value into a version `String` in the format of
    /// `major.minor.patch`, where all components are numbers only, and
    /// has a prefix of the letter 'v'.
    ///
    /// - returns: The formatted version value.
    func formattedVersionString() throws -> String {
        let parts = split(separator: ".")
            .map { (substring: Substring) -> String in
                var string = String(substring)
                string.removeAll { (c: Character) -> Bool in
                    let cSet = CharacterSet(charactersIn: String(c))
                    return !CharacterSet.letters.intersection(cSet).isEmpty
                }
                return string
            }
        if parts.count != 3 {
            throw VersionStringErrors.invalidFormat
        }
        
        return "v" + parts.joined(separator: ".")
    }
}
