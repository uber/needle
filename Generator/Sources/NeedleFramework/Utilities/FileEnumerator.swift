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

/// The supported formats for the sources list file.
enum SourcesListFileFormat {
    /// Newline format, where paths are separated by the newline character.
    case newline
    /// Minimum escaping format, where paths that contain spaces are
    /// escaped with single quotes while paths that don't contain any
    /// spaces are not wrapped with any quotes. Paths are separated by
    /// a single space character.
    case minEscaping

    /// Parse the given `String` value into the format enumeration.
    ///
    /// - parameter value: The `String` value to parse.
    /// - returns: The `SourcesListFileFormat` case. `nil` if the given
    /// string does not match any supported formats.
    static func format(with value: String) -> SourcesListFileFormat? {
        switch value.lowercased() {
        case "newline": return .newline
        case "minescaping": return .minEscaping
        default: return nil
        }
    }
}

/// A utility class that provides file enumeration from a root directory.
class FileEnumerator {

    /// Enumerate all the files in the root URL. If the given URL is a
    /// directory, it is traversed recursively to surface all file URLs.
    /// If the given URL is a file, it is treated as a text file where
    /// each line is assumed to be a path to a file.
    ///
    /// - parameter rootUrl: The root URL to enumerate from.
    /// - parameter sourcesListFormatValue: The optional `String` value of
    /// the format used by the sources list file. If `nil` and the the given
    /// `rootUrl` is a file containing a list of Swift source paths, the
    /// `SourcesListFileFormat.newline` format is used. If the given `rootUrl`
    /// is not a file containing a list of Swift source paths, this value is
    /// ignored.
    /// - parameter handler: The closure to invoke when a file URL is found.
    /// - throws: `FileEnumerationError` if any errors occurred.
    func enumerate(from rootUrl: URL, withSourcesListFormat sourcesListFormatValue: String?, handler: (URL) -> Void) throws {
        if rootUrl.isFileURL {
            if rootUrl.isSwiftSource {
                handler(rootUrl)
            } else {
                let format = try sourcesListFileFormat(from: sourcesListFormatValue, withDefault: .newline)
                let fileUrls = try self.fileUrls(fromSourcesList: rootUrl, with: format)
                for fileUrl in fileUrls {
                    handler(fileUrl)
                }
            }
        } else {
            let enumerator = try newFileEnumerator(for: rootUrl)
            while let nextObjc = enumerator.nextObject() {
                if let fileUrl = nextObjc as? URL {
                    handler(fileUrl)
                }
            }
        }
    }

    // MARK: - Private

    private func sourcesListFileFormat(from stringValue: String?, withDefault defaultFormat: SourcesListFileFormat) throws -> SourcesListFileFormat {
        if let stringValue = stringValue {
            if let parsedFormat = SourcesListFileFormat.format(with: stringValue) {
                return parsedFormat
            } else {
                throw GeneratorError.withMessage("Failed to parse sources list format \(stringValue)")
            }
        } else {
            return defaultFormat
        }
    }

    private func fileUrls(fromSourcesList listUrl: URL, with format: SourcesListFileFormat) throws -> [URL] {
        do {
            let content = try String(contentsOf: listUrl)

            let paths: [String]
            switch format {
            case .newline:
                paths = perLineFilePaths(from: content)
            case .minEscaping:
                paths = minEscapingFilePaths(from: content)
            }

            return paths
                .map { (path: String) -> URL in
                    URL(fileURLWithPath: path)
                }
        } catch {
            throw GeneratorError.withMessage("Failed to read source paths from list file at \(listUrl) \(error)")
        }
    }

    private func perLineFilePaths(from content: String) -> [String] {
        return content
            .split(separator: "\n")
            .compactMap { (substring: Substring) -> String? in
                let string = String(substring).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                return string.isEmpty ? nil : string
            }
    }

    private func minEscapingFilePaths(from content: String) -> [String] {
        // Mixed lines where each line is either a single-quoted minimally escaped paths or a
        // non-escaped path.
        let mixedLines = content
            .replacingOccurrences(of: " '", with: "\n'")
            .replacingOccurrences(of: "' ", with: "'\n")
            .split(separator: "\n")

        var paths = [String]()
        for line in mixedLines {
            // If a line starts with a single quote, then it at least contains a minimally escaped path.
            if line.starts(with: "'") {
                let path = line.replacingOccurrences(of: "'", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !path.isEmpty {
                    paths.append(path)
                }
            }
            // Otherwise the line is a set of paths separated by spaces.
            else {
                let nonEscapedPaths = line
                    .split(separator: " ")
                    .compactMap { (substring: Substring) -> String? in
                        let path = String(substring).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        return path.isEmpty ? nil : path
                    }
                paths.append(contentsOf: nonEscapedPaths)
            }
        }
        return paths
    }

    private func newFileEnumerator(for rootUrl: URL) throws -> FileManager.DirectoryEnumerator {
        let errorHandler = { (url: URL, error: Error) -> Bool in
            fatalError("Failed to traverse \(url) with error \(error).")
        }
        if let enumerator = FileManager.default.enumerator(at: rootUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles], errorHandler: errorHandler) {
            return enumerator
        } else {
            throw GeneratorError.withMessage("Failed traverse \(rootUrl)")
        }
    }
}
