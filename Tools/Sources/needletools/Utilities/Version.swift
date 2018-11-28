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
enum VersionErrors: Error {
    /// If the original value is not in the format of `major.minor.patch`,
    /// where all components are numbers only.
    case invalidFormat
}

/// The utilities of package version.
class Version: Comparable {

    /// The major part.
    let major: Int
    /// The minor part.
    let minor: Int
    /// The patch part.
    let patch: Int
    /// The string representation of this version.
    lazy var stringValue = "v\(major).\(minor).\(patch)"

    /// Initializer.
    ///
    /// - parameter string: The `String` to parse a version from.
    /// - throws: `VersionErrors.invalidFormat` if the given `String` value
    /// is not in the format for `major.minor.patch` where all parts are
    /// digits.
    init(string: String) throws {
        let parts = string.split(separator: ".")
            .map { (substring: Substring) -> String in
                var string = String(substring)
                string.removeAll { (c: Character) -> Bool in
                    let cSet = CharacterSet(charactersIn: String(c))
                    return CharacterSet.decimalDigits.intersection(cSet).isEmpty
                }
                return string
        }
        if parts.count != 3 {
            throw VersionErrors.invalidFormat
        }

        major = Int(parts[0])!
        minor = Int(parts[1])!
        patch = Int(parts[2])!
    }

    /// Set this version as the current version.
    ///
    /// - throws: `VersionErrors.invalidFormat` if the version file parsing
    /// failed.
    func setAsCurrent() throws {
        if let versionFileContent = Version.versionFileContent, let versionFileVersionStartIndex = Version.versionFileVersionStartIndex, let versionFileVersionEndIndex = Version.versionFileVersionEndIndex {
            let newContent = versionFileContent.replacingCharacters(in: versionFileVersionStartIndex..<versionFileVersionEndIndex, with: "\(major).\(minor).\(patch)")
            try newContent.write(toFile: Paths.versionFile, atomically: true, encoding: .utf8)
        } else {
            throw VersionErrors.invalidFormat
        }
    }

    /// Retrieve the current version of the release.
    ///
    /// - returns: The current `Version`.
    /// - throws: `VersionErrors.invalidFormat` if the version file parsing
    /// failed.
    static func currentVersion() throws -> Version {
        if let versionFileContent = versionFileContent, let versionFileVersionStartIndex = versionFileVersionStartIndex, let versionFileVersionEndIndex = versionFileVersionEndIndex {
            let stringValue = String(versionFileContent[versionFileVersionStartIndex..<versionFileVersionEndIndex])
            return try Version(string: stringValue)
        } else {
            throw VersionErrors.invalidFormat
        }
    }

    // MARK: - Comparable

    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major < rhs.major {
            return true
        }
        if lhs.minor < rhs.minor {
            return true
        }
        if lhs.patch < rhs.patch {
            return true
        }
        return false
    }

    static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }

    // MARK: - Private

    static var versionFileContent: String? = {
        let versionFileUrl = URL(fileURLWithPath: Paths.versionFile)
        return try? String(contentsOf: versionFileUrl)
    }()

    static var versionFileVersionStartIndex: String.Index? = {
        let startExpression = try? NSRegularExpression(pattern: "let *version *= *\"", options: [])
        if let startExpression = startExpression, let versionFileContent = versionFileContent {
            let startMatch = startExpression.firstMatch(in: versionFileContent, options: [], range: NSRange(location:0, length:versionFileContent.count))
            if let startMatch = startMatch {
                let startIndexValue = startMatch.range.location + startMatch.range.length
                return versionFileContent.index(versionFileContent.startIndex, offsetBy: startIndexValue)
            }
        }
        return nil
    }()

    static var versionFileVersionEndIndex: String.Index? = {
        let wholeExpression = try? NSRegularExpression(pattern: "let *version *= *\"[\\d.]+", options: [])
        if let wholeExpression = wholeExpression, let versionFileContent = versionFileContent {
            let wholeMatch = wholeExpression.firstMatch(in: versionFileContent, options: [], range: NSRange(location:0, length:versionFileContent.count))
            if let wholeMatch = wholeMatch {
                let endIndexValue = wholeMatch.range.location + wholeMatch.range.length
                return versionFileContent.index(versionFileContent.startIndex, offsetBy: endIndexValue)
            }
        }
        return nil
    }()
}
