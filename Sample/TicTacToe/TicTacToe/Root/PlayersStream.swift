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
    var names: Observable<(String, String)> { get }
}

protocol MutablePlayersStream: PlayersStream {
    func update(players player1: String, player2: String)
}

class PlayersStreamImpl: MutablePlayersStream {

    private let subject = ReplaySubject<(String, String)>.create(bufferSize: 1)

    var names: Observable<(String, String)> {
        return subject.asObservable()
    }

    func update(players player1: String, player2: String) {
        subject.onNext((player1, player2))
    }
}
