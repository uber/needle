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
