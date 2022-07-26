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
import SourceParsingFramework

/// Represents the collection of command line arguments which pertain to parsing Swift source in the Needle Generator project.
struct ParsingOptions: ParsableArguments {
    @Argument(help: "Paths to the root folders of Swift source files, or text files containing paths of Swift source files with specified format.", completion: .file())
    var sourceRootPaths: [String]

    // TODO: use `transform` to get a `SourcesListFileFormat` directly instead of inside `FileEnumerator`.
    @Option(help: "The format of the Swift sources list file. See SourcesListFileFormat for supported format details")
    var sourcesListFormat: String?

    @Option(help: "Filename suffix(es) without extensions to exclude from parsing.")
    var excludeSuffixes: [String] = []

    @Option(help: "Paths components to exclude from parsing.")
    var excludePaths: [String] = []

    @Flag(name: [.customLong("collect-parsing-info"), .customLong("cpi", withSingleDash: true)], help: "Whether or not to collect information for parsing execution timeout errors.")
    var shouldCollectParsingInfo = false

    @Option(help: "The timeout value, in seconds, to use for waiting on parsing tasks.")
    var parsingTimeout: TimeInterval = Needle.defaultTimeout

    @Option(name: [.customLong("retry-parsing-limit")], help: "The maximum number of times parsing Swift source files should be retried in case of timeouts.")
    var retryParsingOnTimeoutLimit: Int = 0

    @Option(help: "The maximum number of tasks to execute concurrently.")
    var concurrencyLimit: Int?

    @Option(name: [.long, .customLong("lv", withSingleDash: true)], help: "The logging level to use.", transform: LoggingLevel.level(from:))
    var loggingLevel: LoggingLevel?

    mutating func validate() throws {
        if let loggingLevel = loggingLevel {
            set(minLoggingOutputLevel: loggingLevel)
        }
    }
}
