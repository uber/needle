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
