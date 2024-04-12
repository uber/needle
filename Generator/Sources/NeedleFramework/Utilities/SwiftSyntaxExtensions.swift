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

// MARK: - Custom-defiend Protocols

/// An entity node is either a Protocol or Class syntax node
protocol EntityNode: SyntaxNodeWithModifiers {
    var typeName: String { get }
    var inheritanceClause: InheritanceClauseSyntax? { get }
}

extension EntityNode {
    /// Checks whether the entity inherits from a certain type with `typeName`
    func inherits(from typeName: String) -> Bool {
        
        let inheritedTypeSyntax = inheritanceClause?.inheritedTypes.first?.type
        // Usually, first token is the inherited type name. But sometimes it could also be the module prefix.
        // In that case, we need to look for the actual type name by checking for `MemberTypeIdentifierSyntax`
        if inheritedTypeSyntax?.firstToken(viewMode: .sourceAccurate)?.nextToken(viewMode: .sourceAccurate)?.tokenKind != TokenKind.period {
            return inheritedTypeSyntax?.firstToken(viewMode: .sourceAccurate)?.text == typeName
        } else {
            return inheritedTypeSyntax?.as(MemberTypeSyntax.self)?.name.text == typeName
        }
    }
    
    var inheritanceHasGenericArgument: Bool {
        let inheritanceTypeToken = inheritanceClause?.inheritedTypes.first?.type
        return inheritanceTypeToken?.as(IdentifierTypeSyntax.self)?.genericArgumentClause != nil ||
        inheritanceTypeToken?.as(MemberTypeSyntax.self)?.genericArgumentClause != nil
    }
}

protocol SyntaxNodeWithModifiers {
    var modifiers: DeclModifierListSyntax { get }
}

extension SyntaxNodeWithModifiers {
    var isInternal: Bool {
        modifiers.first?.name.text == nil || modifiers.first?.name.text == "internal"
    }

    var isPublic: Bool {
        modifiers.first?.name.text == "public"
    }

    var isPrivate: Bool {
        modifiers.first?.name.text == "private"
    }

    var isFileprivate: Bool {
        modifiers.first?.name.text == "fileprivate"
    }
}

// MARK: - SwiftSyntax Protocol Extensions

extension NamedDeclSyntax {
    var typeName: String {
        return name.description.trimmed
    }
}

extension ProtocolDeclSyntax: EntityNode {
    var isDependency: Bool {
        inherits(from: dependencyProtocolName)
    }

    var isPluginExtension: Bool {
        inherits(from: pluginExtensionProtocolName)
    }
}

extension ClassDeclSyntax: EntityNode {
    var isComponent: Bool {
        (inherits(from: componentClassName) && inheritanceHasGenericArgument) || isRoot
    }

    var isPluginizedComponent: Bool {
        ((inherits(from: pluginizedComponentClassName)) || inherits(from: uberPluginizedComponentClassName))
        && typeName != uberPluginizedComponentClassName
        && inheritanceHasGenericArgument
    }

    var isNonCoreComponent: Bool {
        inherits(from: nonCoreComponentClassName) && inheritanceHasGenericArgument
    }

    var isRoot: Bool {
        inherits(from: bootstrapComponentName)
    }
}

extension ExtensionDeclSyntax: EntityNode {
    /// Checks whether the extension syntax node is extending one of components within `componentNames`
    func isExtension(of componentNames: [String]) -> Bool {
        return componentNames.contains(typeName)
    }

    var typeName: String {
        return extendedType.description.trimmed
    }
}

extension VariableDeclSyntax: SyntaxNodeWithModifiers {}
