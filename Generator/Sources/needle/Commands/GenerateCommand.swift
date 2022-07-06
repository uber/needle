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

import ArgumentParser
import Foundation
import NeedleFramework
import SourceParsingFramework

/// The generate command provides the core functionality of needle. It parses
/// Swift source files by recurively scan the directories starting from the
/// specified source path, excluding files with specified suffixes. It then
/// generates the necessary dependency provider code and export to the specified
/// destination path.
struct Generate: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Generate DI code based on Swift source files in a directory or listed in a single text file.")

    @Argument(help: "Path to the destination file of generated Swift DI code.", completion: .file(extensions: ["swift"]))
    var destinationPath: String

    @Flag(name: .customLong("pluginized"), help: "Whether or not to consider plugins when parsing.")
    var scanPlugins = false

    @Option(help: "Additional modules to import in the generated file, in addition to the ones parsed from source files.", completion: .none)
    var additionalImports: [String] = []

    @Option(name: .customLong("header-doc"), help: "Path to custom header doc file to be included at the top of the generated file.", completion: .file())
    var headerDocPath: String?

    @Option(help: "The timeout value, in seconds, to use for waiting on exporting tasks.")
    var exportingTimeout: TimeInterval = Needle.defaultTimeout

    @Option(help: "Emit a file that contains all inputs of the Needle generator invocation. This option only works in conjunction with --pluginized.")
    var emitInputsDepsFile = false

    @OptionGroup
    var parsing: ParsingOptions

    mutating func run() throws {
        let generator: Generator = scanPlugins ? PluginizedGenerator() : Generator()
        do {
            try generator.generate(
                from: parsing.sourceRootPaths,
                withSourcesListFormat: parsing.sourcesListFormat,
                excludingFilesEndingWith: parsing.excludeSuffixes,
                excludingFilesWithPaths: parsing.excludePaths,
                with: additionalImports,
                headerDocPath,
                to: destinationPath,
                shouldCollectParsingInfo: parsing.shouldCollectParsingInfo,
                parsingTimeout: parsing.parsingTimeout,
                exportingTimeout: exportingTimeout,
                retryParsingOnTimeoutLimit: parsing.retryParsingOnTimeoutLimit,
                concurrencyLimit: parsing.concurrencyLimit,
                emitInputsDepsFile: emitInputsDepsFile
            )
        } catch GenericError.withMessage(let message) {
            error(message)
        } catch (let e) {
            error("Unknown error: \(e)")
        }
    }
}
