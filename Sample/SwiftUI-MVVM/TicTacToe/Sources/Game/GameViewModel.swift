//
//  GameViewModel.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/29/21.
//

import Foundation
import SwiftUI
import Combine

protocol GameViewModelProtocol: ObservableObject {
    var boardColors: [[Color]] { get }
    var alertMessage: String? { get set }
    var selection: String? { get set }
    func placeCurrentPlayerMark(at row: Int, col: Int)
    func scoreTapped()
    func reset()
}

private enum Player: Int {
    case player1 = 1
    case player2
    
    var color: Color {
        switch self {
        case .player1:
            return Color.red
        case .player2:
            return Color.blue
        }
    }
}

final class GameViewModel: GameViewModelProtocol {
    private let mutableScoreStream: MutableScoreStream
    private let playersStream: PlayersStream
    @Published var boardColors: [[Color]] = Board.initialColors
    @Published var alertMessage: String? = nil
    @Published var selection: String? = nil
    private var currentPlayer = Player.player1
    private var cancellables = Set<AnyCancellable>()
    
    init(
        mutableScoreStream: MutableScoreStream,
        playersStream: PlayersStream
    ) {
        self.mutableScoreStream = mutableScoreStream
        self.playersStream = playersStream
    }
    
    func placeCurrentPlayerMark(at row: Int, col: Int) {
        guard boardColors[row][col] == .white else { return }
        let currentPlayer = getAndFlipCurrentPlayer()
        boardColors[row][col] = currentPlayer.color
        
        let endGame = checkEndGame()
        if endGame.didEnd {
            if let winner = endGame.winner {
                performOnPlayerNames { [weak self] (player1Name: String, player2Name: String) in
                    let winnerName = winner == .player1 ? player1Name : player2Name
                    let loserName = winner != .player1 ? player1Name : player2Name
                    self?.announce(winner)
                    self?.mutableScoreStream.updateScore(withWinner: winnerName, loser: loserName)
                }
            } else {
                announceDraw()
                mutableScoreStream.updateDraw()
            }
        }
    }
    
    func reset() {
        boardColors = Board.initialColors
        alertMessage = nil
    }
    
    func scoreTapped() {
        selection = Screen.score.rawValue
    }
    
    private func announce(_ winner: Player) {
        performOnPlayerNames { [weak self] (player1Name: String, player2Name: String) in
            let winnerName: String
            switch winner {
            case .player1:
                winnerName = player1Name
            case .player2:
                winnerName = player2Name
            }
            self?.alertMessage = "\(winnerName) Won!"
        }
    }
    
    private func announceDraw() {
        alertMessage = "It's a Tie"
    }
    
    private func performOnPlayerNames(with handler: @escaping (String, String) -> Void) {
        playersStream.names
            .prefix(1)
            .flatMap { (names: (String, String)?) -> AnyPublisher<(String, String), Never> in
                if let names = names {
                    return Just(names).eraseToAnyPublisher()
                } else {
                    return Empty<(String, String), Never>(completeImmediately: false).eraseToAnyPublisher()
                }
            }
            .sink { (player1Name: String, player2Name: String) in
                handler(player1Name, player2Name)
            }
            .store(in: &cancellables)
    }
    
    private func getAndFlipCurrentPlayer() -> Player {
        let currentPlayer = self.currentPlayer
        self.currentPlayer = currentPlayer == .player1 ? .player2 : .player1
        return currentPlayer
    }
    
    private func checkEndGame() -> (winner: Player?, didEnd: Bool) {
        let winner = checkWinner()
        if let winner = winner {
            return (winner, true)
        }
        let isDraw = checkDraw()
        if isDraw {
            return (nil, true)
        }
        return (nil, false)
    }
    
    private func checkDraw() -> Bool {
        for row in 0 ..< 3 {
            for col in 0 ..< 3 {
                if boardColors[row][col] == .white {
                    return false
                }
            }
        }
        return true
    }
    
    private func checkWinner() -> Player? {
        // Rows
        for row in 0..<3 {
            if let winner = boardColors[row].winner() {
                return winner
            }
        }
        
        // Cols
        let transposedBoardColors = boardColors.transposed()
        for col in 0..<3 {
            if let winner = transposedBoardColors[col].winner() {
                return winner
            }
        }
        
        // Diagonals
        let p11 = boardColors[1][1]
        guard p11 != .white else { return nil }
        
        let p00 = boardColors[0][0]
        let p22 = boardColors[2][2]
        let primaryDiagonal = [p00, p11, p22]
        if let winner = primaryDiagonal.winner() {
            return winner
        }
        
        let p02 = boardColors[0][2]
        let p20 = boardColors[2][0]
        let secondaryDiagonal = [p02, p11, p20]
        if let winner = secondaryDiagonal.winner() {
            return winner
        }
        return nil
    }
}

struct Board {
    static let initialColors: [[Color]] = Array(
        repeating: Array(
            repeating: Color.white,
            count: 3
        ),
        count: 3
    )
}

private extension Array where Element == Color {
    func allRed() -> Bool {
        return self == Array(repeating: .red, count: self.count)
    }
    
    func allBlue() -> Bool {
        return self == Array(repeating: .blue, count: self.count)
    }
    
    func winner() -> Player? {
        if self.allRed() {
            return .player1
        } else if self.allBlue() {
            return .player2
        }
        return nil
    }
}

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    // PRECONDITION: `self` must be rectangular, i.e. every row has equal size.
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}
