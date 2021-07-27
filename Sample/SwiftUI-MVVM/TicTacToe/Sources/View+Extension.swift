//
//  View+Extension.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/27/21.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
