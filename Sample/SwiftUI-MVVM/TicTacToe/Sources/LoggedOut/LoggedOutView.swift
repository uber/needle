//
//  LoggedOutView.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/27/21.
//

import SwiftUI

struct LoggedOutView<ViewModel>: View where ViewModel: LoggedOutViewModelProtocol {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .center) {
            TextField("Player 1", text: $viewModel.player1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Player 2", text: $viewModel.player2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Login") {
                viewModel.login()
                hideKeyboard()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .padding(.top)
        }
        .padding()
    }
}
