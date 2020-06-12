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
import SourceParsingFramework

extension Regex {

    /// Creates a regular expression for any class that inherits from the
    /// NeedleFoundation module's base class with given name.
    ///
    /// - parameter className: The name of the base class to check.
    /// - returns: The regular expression.
    static func foundationInheritanceRegex(forClass className: String) -> Regex {
        return Regex(": *(\(needleModuleName).)?\(className)")
    }

    /// Creates a regular expression for any class that inherits from the
    /// NeedleFoundation module's base generic class with given name.
    ///
    /// - parameter className: The name of the base generic class to check.
    /// - returns: The regular expression.
    static func foundationGenericInheritanceRegex(forClass className: String) -> Regex {
        return Regex(": *(\(needleModuleName).)?\(className) *<")
    }

    /// Creates a regular expression for any protocol that inherits from the
    /// NeedleFoundation module's base protocol with given name.
    ///
    /// - parameter className: The name of the base protocol to check.
    /// - returns: The regular expression.
    static func foundationInheritanceRegex(forProtocol protocolName: String) -> Regex {
        return Regex(": *(\(needleModuleName).)?\(protocolName)")
    }
}

extension Array {
    /// Create a dictionary with given sequence of elements.
    public func spm_createDictionary<Key: Hashable, Value>(
        _ uniqueKeysWithValues: (Element) -> (Key, Value)
        ) -> [Key: Value] {
        return Dictionary(uniqueKeysWithValues: self.map(uniqueKeysWithValues))
    }
}

extension URL {
    
    func relativePathByStrippingCommonComponents(baseURL: URL) -> String? {
        
        guard  self.isFileURL && baseURL.isFileURL else {
            return nil
        }
        
        let baseComponents = baseURL.pathComponents
        let destComponents = self.pathComponents
        
        var i = 0
        while i < baseComponents.count && baseComponents[i].lowercased() == destComponents[i].lowercased() {
            i += 1
        }
    
        return destComponents[i...].joined(separator: "/")
    }

}
