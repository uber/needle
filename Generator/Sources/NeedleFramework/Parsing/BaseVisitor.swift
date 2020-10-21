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

import SwiftSyntax
import SourceParsingFramework

/// The base SyntaxVisitor that provides the common utilities,
/// e.g.: parsing function call expressions, properties
class BaseVisitor: SyntaxVisitor {
    var componentToCallExprs: [String: Set<String>] = [:]
    var propertiesDict: [String: [Property]] = [:]
    var currentEntityNode: EntityNode?
    var currentDependencyProtocol: String?
    var imports: [String] = []
    
    /// Whether we are parsing the line of code which declares a Component.
    /// We need this flag to determine if the generic argument we parse later is for the Component.
    var isParsingComponentDeclarationLine: Bool = false
    
    override func visitPost(_ node: FunctionCallExprSyntax) {
        if let callexpr = node.calledExpression.firstToken?.text,
            let currentEntityName = currentEntityNode?.typeName {
            componentToCallExprs[currentEntityName, default: []].insert(callexpr)
        }
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        guard let currentEntityName = currentEntityNode?.typeName else { return }
        let isPrivate = node.isPrivate || currentEntityNode?.isPrivate == true
        let isFileprivate = node.isFileprivate || currentEntityNode?.isFileprivate == true
        
        let memberProperties = node.bindings.compactMap { pattern -> Property? in
            guard let propertyType = pattern.typeAnnotation?.type.description.trimmed,
                let propertyName = pattern.firstToken?.text else {
                    return nil
            }
            if isPrivate || isFileprivate {
                info("\(currentEntityName) (\(propertyName): \(propertyType)) property is private/fileprivate, therefore inaccessible on DI graph.")
                return nil
            } else {
                return Property(name: propertyName, type: propertyType)
            }
        }
        
        propertiesDict[currentEntityName, default: []].append(contentsOf: memberProperties)
    }
    
    override func visitPost(_ node: ImportDeclSyntax) {
        let importStatement = node.withoutTrivia().description.trimmed
        imports.append(importStatement)
    }
    
    override func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
        isParsingComponentDeclarationLine = false
        return .visitChildren
    }
    
    override func visitPost(_ node: SourceFileSyntax) {
        if currentEntityNode == nil {
            imports = []
        }
    }
}
