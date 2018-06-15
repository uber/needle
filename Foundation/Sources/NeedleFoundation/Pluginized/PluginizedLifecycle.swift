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

/// The object that allows an observer to be disposed, thereby ending the
/// observation.
public protocol ObserverDisposable {

    /// Dispose the observation.
    func dispose()
}

/// The lifecycle of a pluginized scope.
public protocol PluginizedLifecycle {

    /// Observe the lifecycle with given observer.
    ///
    /// - parameter observer: The observer closure to invoke when the lifecycle
    /// changes.
    /// - returns: The disposable object that can end the observation.
    func observe(_ observer: @escaping (Bool) -> Void) -> ObserverDisposable
}
