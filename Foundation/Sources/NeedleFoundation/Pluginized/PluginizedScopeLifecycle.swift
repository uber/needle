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

/// The lifecycle of a pluginized scope. This represents the lifecycle of
/// the scope that utilizes a pluginized DI component. In the case of an
/// iOS MVC application, the lifecycle events should be mapped to the view
/// controller lifecycles.
public enum PluginizedScopeLifecycle {
    /// The active lifecycle. This can be represented as a view controller's
    /// `viewDidAppear` lifecycle.
    case active
    /// The inactivate lifecycle. This can be represented as a view
    /// controller's `viewDidDisappear` lifecycle.
    case inactive
    /// The deinit lifecycle. This can be represented as a view controller's
    /// `deinit` lifecycle.
    case `deinit`
}

/// The object that allows an observer to be disposed, thereby ending the
/// observation.
public protocol ObserverDisposable: AnyObject {

    /// Dispose the observation.
    func dispose()
}

/// The observable of the lifecycle events of a pluginized scope.
public protocol PluginizedScopeLifecycleObservable: AnyObject {

    /// Observe the lifecycle events with given observer.
    ///
    /// - parameter observer: The observer closure to invoke when the lifecycle
    /// changes.
    /// - returns: The disposable object that can end the observation.
    func observe(_ observer: @escaping (PluginizedScopeLifecycle) -> Void) -> ObserverDisposable
}
