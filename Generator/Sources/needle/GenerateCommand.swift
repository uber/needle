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

    private let overview = "Generate DI code based on Swift source files in a directory."
    private let sourceRootPath: PositionalArgument<String>
    private let destinationPath: PositionalArgument<String>
    private let suffixes: OptionArgument<[String]>

    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: name, overview: overview)
        sourceRootPath = subparser.add(positional: "sourceRootPath", kind: String.self)
        destinationPath = subparser.add(positional: "destinationPath", kind: String.self)
        suffixes = subparser.add(option: "--suffixes", shortName: "-sf", kind: [String].self, usage: "Filename suffix(es) without extensions to exclude from parsing.", completion: .filename)
    }

    func execute(with arguments: ArgumentParser.Result) {
        if let sourceRootPath = arguments.get(sourceRootPath) {
            if let destinationPath = arguments.get(destinationPath) {
                let suffixes = arguments.get(self.suffixes) ?? []
                Needle.generate(from: sourceRootPath, excludingFilesWithSuffixes: suffixes, to: destinationPath)
            } else {
                fatalError("Missing destination path.")
            }
        } else {
            fatalError("Missing source files root directory.")
        }
    }
}
