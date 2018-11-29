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
import Utility

/// Errors that can occur when parsing the properly formatted version
/// `String`.
enum VersionErrors: Error {
    /// If the original value is not in the format of `major.minor.patch`,
    /// where all components are numbers only.
    case invalidFormat
}

extension Version {

    /// The string representation of this version.
    var stringValue: String {
        return "v\(major).\(minor).\(patch)"
    }

    /// Set this version as the current version.
    ///
    /// - parameter isDryRun: `true` if this execution is a dry run.
    /// - throws: `VersionErrors.invalidFormat` if the version file parsing
    /// failed.
    func setAsCurrent(isDryRun: Bool) throws {
        if let versionFileContent = Version.versionFileContent, let versionFileVersionStartIndex = Version.versionFileVersionStartIndex, let versionFileVersionEndIndex = Version.versionFileVersionEndIndex {
            let newContent = versionFileContent.replacingCharacters(in: versionFileVersionStartIndex..<versionFileVersionEndIndex, with: "\(major).\(minor).\(patch)")
            if !isDryRun {
                try newContent.write(toFile: Paths.versionFile, atomically: true, encoding: .utf8)
            }
        } else {
            throw VersionErrors.invalidFormat
        }
    }

    /// Create a version from the given `String`.
    ///
    /// - parameter string: The `String` to parse a version from.
    /// - throws: `VersionErrors.invalidFormat` if the given `String` value
    /// is not in the format for `major.minor.patch` where all parts are
    /// digits.
    static func from(string: String) throws -> Version {
        if let version = Version(string: string) {
            return version
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
            return try Version.from(string: stringValue)
        } else {
            throw VersionErrors.invalidFormat
        }
    }

    // MARK: - Private

    private static var versionFileContent: String? = {
        let versionFileUrl = URL(fileURLWithPath: Paths.versionFile)
        return try? String(contentsOf: versionFileUrl)
    }()

    private static var versionFileVersionStartIndex: String.Index? = {
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

    private static var versionFileVersionEndIndex: String.Index? = {
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
