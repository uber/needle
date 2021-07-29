//
//  ScoreSheetView.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/28/21.
//

import SwiftUI

struct ScoreSheetView<ViewModel>: View where ViewModel: ScoreSheetViewModelProtocol {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            Color.blue.edgesIgnoringSafeArea(.all)
            VStack(alignment: .center) {
                Text(viewModel.player1Score)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .padding()
                Text(viewModel.player2Score)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .padding()
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .padding()
                .foregroundColor(Color.white)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
