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
import SourceParsingFramework
import SwiftSyntax

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
        super.init(id: TaskIds.astProducerTask.rawValue)
    }

    /// Execute the task and return the AST structure data model.
    ///
    /// - returns: The `AST` data model.
    /// - throws: Any error occurred during execution.
    override func execute() throws -> AST {
        let syntax = try SyntaxParser.parse(sourceUrl)
        let visitor = Visitor()
        visitor.walk(syntax)
        
        return AST(sourceHash: MD5(string: sourceContent), sourceFileSyntax: syntax, imports: visitor.imports)
    }

    // MARK: - Private

    private let sourceUrl: URL
    private let sourceContent: String
}

private final class Visitor: SyntaxVisitor {
    private(set) var imports: [String] = []
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    override func visitPost(_ node: ImportDeclSyntax) {
        let importStatement = node.importTok.text + " " +
            node.path
                .map { $0.name.text }
                .joined(separator: ".")
        imports.append(importStatement)
    }
}
