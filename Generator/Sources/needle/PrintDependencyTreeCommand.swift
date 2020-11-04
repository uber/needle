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

import CommandFramework
import Foundation
import NeedleFramework
import SourceParsingFramework
import TSCUtility

/// A command that prints out the static dependency tree starting at RootComponent.
class PrintDependencyTreeCommand: AbstractCommand {

    /// Initializer.
    ///
    /// - parameter parser: The argument parser to use.
    init(parser: ArgumentParser) {
        super.init(name: "print-dependency-tree", overview: "Prints out the static dependency tree.", parser: parser)
    }

    /// Setup the arguments using the given parser.
    ///
    /// - parameter parser: The argument parser to use.
    override func setupArguments(with parser: ArgumentParser) {
        super.setupArguments(with: parser)

        sourceRootPaths = parser.add(positional: "sourceRootPaths", kind: [String].self, strategy: ArrayParsingStrategy.upToNextOption, usage: "Paths to the root folders of Swift source files, or text files containing paths of Swift source files with specified format.", completion: .filename)
        sourcesListFormat = parser.add(option: "--sources-list-format", kind: String.self, usage: "The format of the Swift sources list file. See SourcesListFileFormat for supported format details", completion: .filename)
        excludeSuffixes = parser.add(option: "--exclude-suffixes", kind: [String].self, usage: "Filename suffix(es) without extensions to exclude from parsing.", completion: .filename)
        excludePaths = parser.add(option: "--exclude-paths", kind: [String].self, usage: "Paths components to exclude from parsing.")
        shouldCollectParsingInfo = parser.add(option: "--collect-parsing-info", shortName: "-cpi", kind: Bool.self, usage: "Whether or not to collect information for parsing execution timeout errors.")
        parsingTimeout = parser.add(option: "--parsing-timeout", kind: Int.self, usage: "The timeout value, in seconds, to use for waiting on parsing tasks.")
        retryParsingOnTimeoutLimit = parser.add(option: "--retry-parsing-limit", kind: Int.self, usage: "The maximum number of times parsing Swift source files should be retried in case of timeouts.")
        concurrencyLimit = parser.add(option: "--concurrency-limit", kind: Int.self, usage: "The maximum number of tasks to execute concurrently.")
        rootComponentName = parser.add(option: "--root-component-name", kind: String.self, usage: "Root component name for the dependency tree. Defaults to \"RootComponent\".")
    }

    /// Execute the command.
    ///
    /// - parameter arguments: The command line arguments to execute the
    /// command with.
    override func execute(with arguments: ArgumentParser.Result) {
        if let sourceRootPaths = arguments.get(sourceRootPaths) {
                let sourcesListFormat = arguments.get(self.sourcesListFormat) ?? nil
                let excludeSuffixes = arguments.get(self.excludeSuffixes) ?? []
                let excludePaths = arguments.get(self.excludePaths) ?? []
                let shouldCollectParsingInfo = arguments.get(self.shouldCollectParsingInfo) ?? false
                let parsingTimeout = arguments.get(self.parsingTimeout, withDefault: defaultTimeout)
                let retryParsingOnTimeoutLimit = arguments.get(self.retryParsingOnTimeoutLimit) ?? 0
                let concurrencyLimit = arguments.get(self.concurrencyLimit) ?? nil
                let rootComponentName = arguments.get(self.rootComponentName) ?? "RootComponent"

                let generator = Generator()
                do {
                    try generator.printDependencyTree(from: sourceRootPaths, withSourcesListFormat: sourcesListFormat, excludingFilesEndingWith: excludeSuffixes, excludingFilesWithPaths: excludePaths, shouldCollectParsingInfo: shouldCollectParsingInfo, parsingTimeout: parsingTimeout, retryParsingOnTimeoutLimit: retryParsingOnTimeoutLimit, concurrencyLimit: concurrencyLimit, rootComponentName: rootComponentName)
                } catch GenericError.withMessage(let message) {
                    error(message)
                } catch (let e) {
                    error("Unknown error: \(e)")
                }
        } else {
            error("Missing source files root directories.")
        }
    }

    // MARK: - Private

    private var sourceRootPaths: PositionalArgument<[String]>!
    private var sourcesListFormat: OptionArgument<String>!
    private var excludeSuffixes: OptionArgument<[String]>!
    private var excludePaths: OptionArgument<[String]>!
    private var shouldCollectParsingInfo: OptionArgument<Bool>!
    private var parsingTimeout: OptionArgument<Int>!
    private var retryParsingOnTimeoutLimit: OptionArgument<Int>!
    private var concurrencyLimit: OptionArgument<Int>!
    private var rootComponentName: OptionArgument<String>!
}
