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

/// Each available command for needle (needle <command> <params>) has a
/// name that is used to decide which subparser to use by main()
protocol Command {
    /// Name used to check which of the Commands to apply
    var name: String { get }
    /// Initializer, sets up the command-line flags
    init(parser: ArgumentParser)
    /// If the name matches, this method is used to process the command-line params and execute
    func run(with arguments: ArgumentParser.Result)
}

/// This command just scans files and produces dummy output, created for timing
/// and prototyping purposes. Will be deleted soon.
class ScanCommand: Command {
    let name = "scan"

    private let overview = "Scan's all swift files in the directory specified"
    private let dir: PositionalArgument<String>
    private let suffixes: OptionArgument<[String]>

    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: name, overview: overview)
        dir = subparser.add(positional: "directory", kind: String.self)
        suffixes = subparser.add(option: "--suffixes", shortName: "-s", kind: [String].self, usage: "Filename suffix(es) to skip (not including extension)", completion: .filename)
    }

    func run(with arguments: ArgumentParser.Result) {
        if let path = arguments.get(dir) {
            let suffixes = arguments.get(self.suffixes)
            ProviderGenerator().scanFiles(mode: .serial, atPath: path, withoutSuffixes: suffixes)
        }
    }
}

/// The generate command provides the core functionality of needle. It scans
/// all the relevant files in the directories and builds a DI tree, then it
/// outputs provider classes to satisfy the dependency protocols found.
class GenerateCommand: Command {
    let name = "generate"

    private let overview = "Generate DI provider classes based on the source scanned"
    private let dir: PositionalArgument<String>
    private let suffixes: OptionArgument<[String]>

    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: name, overview: overview)
        dir = subparser.add(positional: "directory", kind: String.self)
        suffixes = subparser.add(option: "--suffixes", shortName: "-s", kind: [String].self, usage: "Filename suffix(es) to skip (not including extension)", completion: .filename)
    }

    func run(with arguments: ArgumentParser.Result) {
        // TODO Replace with entry point that does both parsing and generating.
//        if let path = arguments.get(dir) {
//            let suffixes = arguments.get(self.suffixes)
//            do {
//                try DependencyGraphParser().parse(from: URL(fileURLWithPath: path), excludingFilesWithSuffixes: suffixes ?? [], using: SequenceExecutorImpl(name: "main"))
//            } catch {
//                fatalError()
//            }
//        }
    }
}
