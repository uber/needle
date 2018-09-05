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
class GenerateCommand: Command {

    /// The name of the command.
    let name = "generate"

    private let overview = "Generate DI code based on all Swift source files in a directory."
    private let destinationPath: PositionalArgument<String>
    private let sourceRootPaths: PositionalArgument<[String]>
    private let suffixes: OptionArgument<[String]>
    private let additionalImports: OptionArgument<[String]>
    private let scanPlugins: OptionArgument<Bool>
    private let headerDocPath: OptionArgument<String>

    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: name, overview: overview)
        destinationPath = subparser.add(positional: "destinationPath", kind: String.self, usage: "Path to the destination file of generated Swift DI code.", completion: .filename)
        sourceRootPaths = subparser.add(positional: "sourceRootPaths", kind: [String].self, strategy: ArrayParsingStrategy.upToNextOption, usage: "Path to the root folder of Swift source files.", completion: .filename)
        suffixes = subparser.add(option: "--suffixes", shortName: "-sfx", kind: [String].self, usage: "Filename suffix(es) without extensions to exclude from parsing.", completion: .filename)
        scanPlugins = subparser.add(option: "--pluginized", shortName: "-p", kind: Bool.self, usage: "Whether or not to consider plugins when parsing.")
        additionalImports = subparser.add(option: "--additional-imports", shortName: "-ai", kind: [String].self, usage: "Additional modules to import in the generated file, in addition to the ones parsed from source files.", completion: .none)
        headerDocPath = subparser.add(option: "--header-doc", shortName: "-hd", kind: String.self, usage: "Path to custom header doc file to be included at the top of the generated file.", completion: .filename)
    }

    func execute(with arguments: ArgumentParser.Result) {
        if let destinationPath = arguments.get(destinationPath) {
            if let sourceRootPaths = arguments.get(sourceRootPaths) {
                let suffixes = arguments.get(self.suffixes) ?? []
                let additionalImports = arguments.get(self.additionalImports) ?? []
                let scanPlugins = arguments.get(self.scanPlugins) ?? false
                let headerDocPath = arguments.get(self.headerDocPath) ?? nil
                if scanPlugins {
                    PluginizedNeedle.generate(from: sourceRootPaths, excludingFilesWith: suffixes, with: additionalImports, headerDocPath, to: destinationPath)
                } else {
                    Needle.generate(from: sourceRootPaths, excludingFilesWith: suffixes, with: additionalImports, headerDocPath, to: destinationPath)
                }
            } else {
                fatalError("Missing source files root directories.")
            }
        } else {
            fatalError("Missing destination path.")
        }
    }
}
