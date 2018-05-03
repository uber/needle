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

/// A task that parses a Swift source content and produces Swift AST that can then be
/// parsed into the dependnecy graph.
class ASTProducerTask: SequencedTask {

    /// The source URL.
    let sourceUrl: URL
    /// The source content to be parsed into AST.
    let sourceContent: String

    /// Initializer.
    ///
    /// - parameter sourceUrl: The source URL.
    /// - parameter sourceContent: The source content to be parsed into AST.
    init(sourceUrl: URL, sourceContent: String) {
        self.sourceUrl = sourceUrl
        self.sourceContent = sourceContent
    }

    func execute() -> SequencedTask? {
        let file = File(contents: sourceContent)
        do {
            let structure = try Structure(file: file)
            return ASTParserTask(structure: structure)
        } catch {
            fatalError("Failed to parse AST for source at \(sourceUrl)")
        }
    }
}
