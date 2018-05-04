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
import SourceKittenFramework

/// A task that parses Swift AST into in-memory dependency graph data models.
class ASTParserTask: SequencedTask<[Component]> {

    /// The AST structure of the file to parse.
    let structure: Structure

    /// Initializer.
    ///
    /// - parameter structure: The AST structure of the file to parse.
    init(structure: Structure) {
        self.structure = structure
    }

    /// Execute the task and returns the in-memory dependency graph data models.
    /// This is the last task in the sequence.
    ///
    /// - returns: `nil`.
    override func execute() -> ExecutionResult<[Component]> {
        return .endOfSequence([])
    }
}
