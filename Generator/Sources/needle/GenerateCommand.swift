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
import NeedleFramework
import Utility

/// The generate command provides the core functionality of needle. It parses
/// Swift source files by recurively scan the directories starting from the
/// specified source path, excluding files with specified suffixes. It then
/// generates the necessary dependency provider code and export to the specified
/// destination path.
class GenerateCommand: AbstractCommand {

    /// Initializer.
    ///
    /// - parameter parser: The argument parser to use.
    init(parser: ArgumentParser) {
        super.init(name: "generate", overview: "Generate DI code based on Swift source files in a directory or listed in a single text file.", parser: parser)
    }

    /// Setup the arguments using the given parser.
    ///
    /// - parameter parser: The argument parser to use.
    override func setupArguments(with parser: ArgumentParser) {
        super.setupArguments(with: parser)

        destinationPath = parser.add(positional: "destinationPath", kind: String.self, usage: "Path to the destination file of generated Swift DI code.", completion: .filename)
        sourceRootPaths = parser.add(positional: "sourceRootPaths", kind: [String].self, strategy: ArrayParsingStrategy.upToNextOption, usage: "Paths to the root folders of Swift source files, or text files containing paths of Swift source files separated by new-line.", completion: .filename)
        sourcesListFormat = parser.add(option: "--sources-list-format", shortName: "-srclf", kind: String.self, usage: "The format of the Swift sources list file. See SourcesListFileFormat for supported format details", completion: .filename)
        excludeSuffixes = parser.add(option: "--exclude-suffixes", shortName: "-esfx", kind: [String].self, usage: "Filename suffix(es) without extensions to exclude from parsing.", completion: .filename)
        excludePaths = parser.add(option: "--exclude-paths", shortName: "-epaths", kind: [String].self, usage: "Paths components to exclude from parsing.")
        scanPlugins = parser.add(option: "--pluginized", shortName: "-p", kind: Bool.self, usage: "Whether or not to consider plugins when parsing.")
        additionalImports = parser.add(option: "--additional-imports", shortName: "-ai", kind: [String].self, usage: "Additional modules to import in the generated file, in addition to the ones parsed from source files.", completion: .none)
        headerDocPath = parser.add(option: "--header-doc", shortName: "-hd", kind: String.self, usage: "Path to custom header doc file to be included at the top of the generated file.", completion: .filename)
    }

    /// Execute the command.
    ///
    /// - parameter arguments: The command line arguments to execute the
    /// command with.
    override func execute(with arguments: ArgumentParser.Result) {
        super.execute(with: arguments)

        if let destinationPath = arguments.get(destinationPath) {
            if let sourceRootPaths = arguments.get(sourceRootPaths) {
                let sourcesListFormat = arguments.get(self.sourcesListFormat) ?? nil
                let excludeSuffixes = arguments.get(self.excludeSuffixes) ?? []
                let excludePaths = arguments.get(self.excludePaths) ?? []
                let additionalImports = arguments.get(self.additionalImports) ?? []
                let scanPlugins = arguments.get(self.scanPlugins) ?? false
                let headerDocPath = arguments.get(self.headerDocPath) ?? nil
                if scanPlugins {
                    PluginizedNeedle.generate(from: sourceRootPaths, withSourcesListFormat: sourcesListFormat, excludingFilesEndingWith: excludeSuffixes, excludingFilesWithPaths: excludePaths, with: additionalImports, headerDocPath, to: destinationPath)
                } else {
                    Needle.generate(from: sourceRootPaths, withSourcesListFormat: sourcesListFormat, excludingFilesEndingWith: excludeSuffixes, excludingFilesWithPaths: excludePaths, with: additionalImports, headerDocPath, to: destinationPath)
                }
            } else {
                fatalError("Missing source files root directories.")
            }
        } else {
            fatalError("Missing destination path.")
        }
    }

    // MARK: - Private

    private var destinationPath: PositionalArgument<String>!
    private var sourceRootPaths: PositionalArgument<[String]>!
    private var sourcesListFormat: OptionArgument<String>!
    private var excludeSuffixes: OptionArgument<[String]>!
    private var excludePaths: OptionArgument<[String]>!
    private var additionalImports: OptionArgument<[String]>!
    private var scanPlugins: OptionArgument<Bool>!
    private var headerDocPath: OptionArgument<String>!
}
