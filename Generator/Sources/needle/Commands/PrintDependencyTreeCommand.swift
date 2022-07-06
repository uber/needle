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

/// A command that prints out the static dependency tree starting at RootComponent.
struct PrintDependencyTree: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Prints out the static dependency tree.")

    @OptionGroup
    var parsing: ParsingOptions

    @Option(help: "Root component name for the dependency tree. Defaults to \"RootComponent\".")
    var rootComponentName: String = "RootComponent"

    mutating func run() throws {
        let generator = Generator()
        do {
            try generator.printDependencyTree(
                from: parsing.sourceRootPaths,
                withSourcesListFormat: parsing.sourcesListFormat,
                excludingFilesEndingWith: parsing.excludeSuffixes,
                excludingFilesWithPaths: parsing.excludePaths,
                shouldCollectParsingInfo: parsing.shouldCollectParsingInfo,
                parsingTimeout: parsing.parsingTimeout,
                retryParsingOnTimeoutLimit: parsing.retryParsingOnTimeoutLimit,
                concurrencyLimit: parsing.concurrencyLimit,
                rootComponentName: rootComponentName
            )
        } catch GenericError.withMessage(let message) {
            error(message)
        } catch (let e) {
            error("Unknown error: \(e)")
        }
    }
}
