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

/// The base protocol for a non-core scope defining its lifecycle to
/// support scope activation and deactivation.
///
/// - note: A separate protocol is used to allow `PluginizableComponent`
/// to declare a non-core component generic without having to specify the
/// dependency protocol nested generics.
public protocol NonCoreScope: AnyObject {
    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    init(parent: Scope)

    /// Indicate the corresponding core scope has become active, thereby
    /// activating this non-core component as well.
    ///
    /// - note: This method is automatically invoked when the non-core component
    /// is paired with a `PluginizableComponent` that is bound to a lifecycle.
    /// Otherwise, this method must be explicitly invoked.
    func scopeDidBecomeActive()

    /// Indicate the corresponding core scope has become inactive, thereby
    /// deactivating this non-core component as well.
    ///
    /// - note: This method is automatically invoked when the non-core component
    /// is paired with a `PluginizableComponent` that is bound to a lifecycle.
    /// Otherwise, this method must be explicitly invoked.
    func scopeDidBecomeInactive()

    #if NEEDLE_DYNAMIC
    func check<T>(property: String) -> T?
    #endif
}

/// The base non-core component class. All non-core components should inherit
/// from this class.
open class NonCoreComponent<DependencyType>: Component<DependencyType>, NonCoreScope {

    /// Initializer.
    ///
    /// - parameter parent: The parent component of this component.
    public required override init(parent: Scope) {
        #if NEEDLE_DYNAMIC
        super.init(parent: parent, nonCore: true)
        #else
        super.init(parent: parent)
        #endif
    }

    /// Indicate the corresponding core scope has become active, thereby
    /// activating this non-core component as well.
    ///
    /// - note: This method is automatically invoked when the non-core component
    /// is paired with a `PluginizableComponent` that is bound to a lifecycle.
    /// Otherwise, this method must be explicitly invoked.
    open func scopeDidBecomeActive() {}

    /// Indicate the corresponding core scope has become inactive, thereby
    /// deactivating this non-core component as well.
    ///
    /// - note: This method is automatically invoked when the non-core component
    /// is paired with a `PluginizableComponent` that is bound to a lifecycle.
    /// Otherwise, this method must be explicitly invoked.
    open func scopeDidBecomeInactive() {}

    #if NEEDLE_DYNAMIC
    public func check<T>(property: String) -> T? {
        guard let itemCloure = localTable[property] else {
            return nil
        }
        guard let result = itemCloure() as? T else {
            fatalError("Incorrect type for \(property) found in the lookup table")
        }
        return result
    }
    #endif
}
