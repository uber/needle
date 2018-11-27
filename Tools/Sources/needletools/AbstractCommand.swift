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
import NeedleToolsFramework
import Utility

/// The base class of all commands that perform a set of logic common
/// to all commands.
class AbstractCommand: Command {
    /// The name used to check if this command should be executed.
    let name: String

    /// Initializer.
    ///
    /// - parameter name: The name used to check if this command should
    /// be executed.
    /// - parameter overview: The overview description of this command.
    /// - parameter parser: The argument parser to use.
    init(name: String, overview: String, parser: ArgumentParser) {
        self.name = name
        let subparser = parser.add(subparser: name, overview: overview)
        setupArguments(with: subparser)
    }

    /// Setup the arguments using the given parser.
    ///
    /// - parameter parser: The argument parser to use.
    func setupArguments(with parser: ArgumentParser) {}

    /// Execute the command.
    ///
    /// - parameter arguments: The command line arguments to execute the
    /// command with.
    func execute(with arguments: ArgumentParser.Result) {}
}
