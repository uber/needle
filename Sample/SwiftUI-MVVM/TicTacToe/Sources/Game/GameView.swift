//
//  GameView.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/29/21.
//

import SwiftUI

struct GameView<ViewModel>: View where ViewModel: GameViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    let scoreSheetBuilder: ScoreSheetBuilder
    
    var body: some View {
        ZStack {
            Color.purple.edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {
                NavigationLink(
                    destination: scoreSheetBuilder.scoreSheetView,
                    tag: Screen.score.rawValue,
                    selection: $viewModel.selection
                ) {
                    EmptyView()
                }
                GridStack(rows: 3, columns: 3, spacing: 0) { row, col in
                    Button(action: {
                        viewModel.placeCurrentPlayerMark(at: row, col: col)
                    }, label: {
                        Text("")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(viewModel.boardColors[row][col])
                            .border(Color.gray, width: 2)
                    })
                }
                Button("High Scores") {
                    viewModel.scoreTapped()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
            }
        }
        .alert(item: $viewModel.alertMessage) { msg in
            Alert(title: Text("TicTacToe"), message: Text(msg), dismissButton: .default(Text("OK"), action: {
                viewModel.reset()
            }))
        }
    }
}

extension String: Identifiable {
    public var id: String {
        return self
    }
}
