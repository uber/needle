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

import TSCBasic
import CommandFramework
import Foundation
import NeedleFramework
import SourceParsingFramework
import TSCUtility

func main() {
    let parser = ArgumentParser(usage: "<subcommand> <options>", overview: "Needle DI code generator.")
    let commands = initializeCommands(with: parser)
    let inputs = Array(CommandLine.arguments.dropFirst())
    do {
        let args = try parser.parse(inputs)
        execute(commands, with: parser, args)
    } catch (let e) {
        error("Command-line pasing error (use --help for help): \(e)")
    }
}

private func initializeCommands(with parser: ArgumentParser) -> [Command] {
    return [
        VersionCommand(parser: parser),
        GenerateCommand(parser: parser),
        PrintDependencyTreeCommand(parser: parser)
    ]
}

private func execute(_ commands: [Command], with parser: ArgumentParser, _ args: ArgumentParser.Result) {
    if let subparserName = args.subparser(parser) {
        for command in commands {
            if subparserName == command.name {
                command.execute(with: args)
            }
        }
    } else {
        parser.printUsage(on: stdoutStream)
    }
}

main()
