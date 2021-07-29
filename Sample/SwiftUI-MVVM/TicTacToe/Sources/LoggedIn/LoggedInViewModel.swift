//
//  LoggedInViewModel.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/28/21.
//

import Foundation
import Combine

protocol LoggedInViewModelProtocol: ObservableObject {
    var selection: String? { get set }
    func gameTapped()
    func scoreTapped()
}

final class LoggedInViewModel: LoggedInViewModelProtocol {
    private let scoreStream: ScoreStream
    private var gameCancellable: Cancellable?
    @Published var selection: String? = nil
    
    init(scoreStream: ScoreStream) {
        self.scoreStream = scoreStream
    }
    
    func scoreTapped() {
        selection = Screen.score.rawValue
    }
    
    func gameTapped() {
        selection = Screen.game.rawValue
        gameCancellable?.cancel()
        gameCancellable = scoreStream.gameDidEnd
            .prefix(1)
            .sink(receiveValue: { _ in
                // TODO: dismiss
            })
    }
    
    deinit {
        gameCancellable?.cancel()
    }
}
