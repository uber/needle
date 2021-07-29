//
//  LoggedInView.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/28/21.
//

import SwiftUI

struct LoggedInView<ViewModel>: View where ViewModel: LoggedInViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    let scoreSheetBuilder: ScoreSheetBuilder
    let gameBuilder: GameBuilder
    
    var body: some View {
        ZStack {
            Color.yellow.edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {
                NavigationLink(
                    destination: gameBuilder.gameView,
                    tag: Screen.game.rawValue,
                    selection: $viewModel.selection
                ) {
                    EmptyView()
                }
                NavigationLink(
                    destination: scoreSheetBuilder.scoreSheetView,
                    tag: Screen.score.rawValue,
                    selection: $viewModel.selection
                ) {
                    EmptyView()
                }
                Button("Play TicTacToe") {
                    viewModel.gameTapped()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundColor(.white)
                Button("High Scores") {
                    viewModel.scoreTapped()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
            }
            .padding()
        }
    }
}
