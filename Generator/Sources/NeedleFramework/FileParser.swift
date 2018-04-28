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

public struct Component {
    let name: String
    let dependency: String
    var members: [(String, String)]
    let filePath: String
    let offsetInFile: Int
    var children: [Component]
    var parents: [Component]

    init(name: String, dependency: String, members: [(String, String)], filePath: String) {
        self.name = name
        self.dependency = dependency
        self.members = members
        self.filePath = filePath
        self.offsetInFile = 0
        self.children = []
        self.parents = []
    }

    public func fakeGenerateForTiming() -> String {

        let middle = members.map { (name, kind) in
            return """
                var \(name) : \(kind) = {
                    return dependeny.\(name)
                }


            """
        }.joined()

        let result = """
        class \(self.name)Provider {
        \(middle)}

        
        """

        return result
    }
}

public struct Dependency {
    var name: String
    var members: [(String, String)]
    let filePath: String
    let offsetInFile: Int
}

public class FileParser {
    private let file: File
    private let path: String
    private let componentsExpression = RegEx("^Component *<(.+)>$")

    public init(contents: String, path: String) {
        self.file = File(contents: contents)
        self.path = path
    }

    private func parseClass(_ structure: [String: SourceKitRepresentable], filePath: String) -> Component? {
        var dep: String?
        for inheritedType in structure.inheritedTypes {
            if let match = componentsExpression.firstMatch(inheritedType),
                let range = Range(match.range(at: 1), in: inheritedType) {
                dep = String(inheritedType[range])
            }
        }
        guard let dependency = dep else { return nil }

        let vars: [(String, String)] = structure.substructure.flatMap { item in
            if let name = item.name, let typeName = item.typeName, let kind = item.kind {
                if SwiftDeclarationKind(rawValue: kind) == .varInstance {
                    return (name, typeName)
                }
            }
            return nil
        }
        return Component(name: structure.name!, dependency: dependency, members: vars, filePath: filePath)
    }

    private func parseProtocol(_ structure: [String: SourceKitRepresentable], filePath: String) -> Dependency? {
        let vars: [(String, String)] = structure.substructure.flatMap { item in
            if let name = item.name, let typeName = item.typeName, let kind = item.kind, SwiftDeclarationKind(rawValue: kind) == .varInstance {
                return (name, typeName)
            } else {
                return nil
            }
        }
        return Dependency(name: structure.name!, members: vars, filePath: filePath, offsetInFile: 0)
    }

    public func parse() -> ([Component], [Dependency])? {
        let result = try? Structure(file: file)

        if let result = result {
            let substructure = result.dictionary.substructure

            // Find component subclasses
            let components: [Component] = substructure.flatMap { structure in
                if let kind = structure.kind, SwiftDeclarationKind(rawValue: kind) == .class {
                    return parseClass(structure, filePath: path)
                } else {
                    return nil
                }
            }
            let dependencyNames = components.map { $0.dependency }

            // Scan for dependency protocols using the list generated above
            let dependencies: [Dependency] = substructure.flatMap { structure in
                if let name = structure.name, let kind = structure.kind, SwiftDeclarationKind(rawValue: kind) == .protocol {
                    if dependencyNames.contains(name) {
                        return parseProtocol(structure, filePath: path)
                    }
                }
                return nil
            }
            return (components, dependencies)
        }

        return nil
    }
}
