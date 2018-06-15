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
import RxSwift

protocol PlayersStream {
    var names: Observable<(String, String)?> { get }
}

protocol MutablePlayersStream: PlayersStream {
    func update(player1: String?, player2: String?)
}

class PlayersStreamImpl: MutablePlayersStream {

    private let subject = BehaviorSubject<(String, String)?>(value: nil)

    var names: Observable<(String, String)?> {
        return subject.asObservable()
    }

    func update(player1: String?, player2: String?) {
        let player1Name: String
        if let player1 = player1, !player1.isEmpty {
            player1Name = player1
        } else {
            player1Name = "Player 1"
        }
        let player2Name: String
        if let player2 = player2, !player2.isEmpty {
            player2Name = player2
        } else {
            player2Name = "Player 2"
        }
        subject.onNext((player1Name, player2Name))
    }
}
