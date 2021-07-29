//
//  GridStack.swift
//  TicTacToe
//
//  Created by MIC KARAGIORGOS on 7/29/21.
//

import SwiftUI

struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let spacing: CGFloat?
    let content: (Int, Int) -> Content

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0 ..< rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0 ..< columns, id: \.self) { column in
                        content(row, column)
                    }
                }
            }
        }
    }

    init(
        rows: Int,
        columns: Int,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (Int, Int) -> Content
    ) {
        self.rows = rows
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
}
