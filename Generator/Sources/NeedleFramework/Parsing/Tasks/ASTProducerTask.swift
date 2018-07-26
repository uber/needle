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

import Concurrency
import Foundation
import SourceKittenFramework

/// A task that parses a Swift source content and produces Swift AST that
/// can then be parsed into the dependnecy graph.
class ASTProducerTask: AbstractTask<AST> {

    /// Initializer.
    ///
    /// - parameter sourceUrl: The source URL.
    /// - parameter sourceContent: The source content to be parsed into AST.
    init(sourceUrl: URL, sourceContent: String) {
        self.sourceUrl = sourceUrl
        self.sourceContent = sourceContent
    }

    /// Execute the task and return the AST structure data model.
    ///
    /// - returns: The `AST` data model.
    override func execute() -> AST {
        let file = File(contents: sourceContent)
        do {
            let structure = try Structure(file: file)
            let imports = parseImports()
            return AST(structure: structure, imports: imports)
        } catch {
            fatalError("Failed to parse AST for source at \(sourceUrl)")
        }
    }

    // MARK: - Private

    private let sourceUrl: URL
    private let sourceContent: String

    private func parseImports() -> [String] {
        // Use regex since SourceKit does not have a command that parses imports.
        let regex = Regex("\\bimport +[^\\n;]+")
        let matches = regex.matches(in: sourceContent)

        let spacesAndNewLinesSet = CharacterSet.whitespacesAndNewlines
        return matches
            .compactMap { (match: NSTextCheckingResult) in
                return sourceContent.substring(with: match.range)?.trimmingCharacters(in: spacesAndNewLinesSet)
        }
    }
}
