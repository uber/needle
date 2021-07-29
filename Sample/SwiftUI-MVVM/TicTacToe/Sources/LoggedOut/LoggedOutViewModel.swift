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

protocol LoggedOutViewModelProtocol: ObservableObject {
    var player1: String { get set }
    var player2: String { get set }
    func login()
}

final class LoggedOutViewModel: LoggedOutViewModelProtocol {
    @Published var player1: String = ""
    @Published var player2: String = ""
    
    private let mutablePlayersStream: MutablePlayersStream

    init(mutablePlayersStream: MutablePlayersStream) {
        self.mutablePlayersStream = mutablePlayersStream
    }
    
    func login() {
        mutablePlayersStream.update(player1: player1, player2: player2)
    }
}

enum Screen: String {
    case game
    case score
}
