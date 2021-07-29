//
//  LoggedOutViewModel.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/27/21.
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
