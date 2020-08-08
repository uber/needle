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

protocol PlayersStoreListener: class {
    func didUpdate(names: (String, String))
}

protocol PlayersStore {
    var names: (String, String)? { get }
    func add(listener: PlayersStoreListener)
    func remove(listener: PlayersStoreListener)
}

protocol MutablePlayersStore: PlayersStore {
    func update(player1: String?, player2: String?)
}

class PlayersStoreImpl: MutablePlayersStore {

    private(set) var names: (String, String)?
    private var listeners: [PlayersStoreListener]  = []

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
        
        let newNames = (player1Name, player2Name)
        names = newNames
        
        listeners.forEach { $0.didUpdate(names: newNames) } 
    }
    
    func add(listener: PlayersStoreListener) {
        let listenerAlreadyExists = listeners.contains { $0 === listener }
        if listenerAlreadyExists {
            return
        }
        
        listeners.append(listener)
    }
    
    func remove(listener: PlayersStoreListener) {
        let index = listeners.firstIndex { $0 === listener }
        if let index = index {
            listeners.remove(at: index)
        }
    }
}
