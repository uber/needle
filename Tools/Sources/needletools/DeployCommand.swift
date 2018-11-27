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
import Utility

/// The command to deploy a new version of Needle to all distribution
/// channels.
class DeployCommand: AbstractCommand {
    
    /// Initializer.
    ///
    /// - parameter parser: The argument parser to use.
    init(parser: ArgumentParser) {
        super.init(name: "deploy", overview: "Create and deploy a new Needle release.", parser: parser)
    }

    /// Setup the arguments using the given parser.
    ///
    /// - parameter parser: The argument parser to use.
    override func setupArguments(with parser: ArgumentParser) {
        super.setupArguments(with: parser)

        versionNumberString = parser.add(positional: "versionNumberString", kind: String.self, usage: "The version number string.")
    }
    
    /// Execute the command.
    ///
    /// - parameter arguments: The command line arguments to execute the
    /// command with.
    override func execute(with arguments: ArgumentParser.Result) {
        super.execute(with: arguments)

        if let versionNumberString = arguments.get(self.versionNumberString) {
            do {
                let versionString = try versionNumberString.formattedVersionString()
                if assertDeploy(with: versionString) {
                    archieveGenerator()
                    pushBinary(with: versionString)
                    print("Finished deploying \(versionString)")
                }
            } catch {
                fatalError("Invalid version string format. The version must be in the format of `major.minor.patch`, where all components are numbers only.")
            }
        } else {
            fatalError("Version number string must be specified.")
        }
    }
    
    // MARK: - Private
    
    private var versionNumberString: PositionalArgument<String>!
    
    private func assertDeploy(with versionString: String) -> Bool {
        print("Are you sure you want to deploy a new version of Needle with the version \(versionString)? [y/n]")
        let response = readLine(strippingNewline: true)?.lowercased() ?? ""
        return response == "y"
    }
    
    private func archieveGenerator() {
        print("Archiving generator binary...")

        let archieveResult = CompilerUtilities.archiveGenerator()
        if !archieveResult.status {
            fatalError(archieveResult.error)
        }

        let moveResult = ProcessUtilities.move(Paths.generatorArchieve, to: Paths.generatorBin)
        if !moveResult.status {
            fatalError(moveResult.error)
        }
    }
    
    private func pushBinary(with versionString: String) {
        print("Pushing new binary (\(Paths.generatorBinary)) to Git remote master branch...")

        do {
            try GitUtilities.push(file: Paths.generatorBinary, withVersion: versionString)
        } catch {
            fatalError("\(error)")
        }
    }
}
