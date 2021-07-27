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
import Combine

protocol RootViewModelProtocol: ObservableObject {
    var state: RootChildStates { get }
}

final class RootViewModel: RootViewModelProtocol {
    @Published var state: RootChildStates = .loggedOut
    private let playerStream: PlayersStream
    private var playersStreamCancellable: Cancellable?

    init(playerStream: PlayersStream) {
        self.playerStream = playerStream
        updateFeature()
    }

    func updateFeature() {
        state = .loggedOut
        if playersStreamCancellable != nil {
            return
        }
        
        playersStreamCancellable = playerStream.names
            .map { (names: (String, String)?) in
                names == nil ? RootChildStates.loggedOut : RootChildStates.loggedIn
            }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] (state: RootChildStates) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.state = state
            })
    }
    
    deinit {
        playersStreamCancellable?.cancel()
    }
}

enum RootChildStates {
    case loggedOut
    case loggedIn
}
