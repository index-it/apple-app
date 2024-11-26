//
//  ListsHomePage.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI

struct ListsTabView: View {
    var body: some View {
        ScrollView {
             LazyVGrid(columns: columns) {
                 ForEach(0x1f600...0x1f679, id: \.self) { value in
                     Text(String(format: "%x", value))
                     Text(emoji(value))
                         .font(.largeTitle)
                 }
             }
         }
    }
}

#Preview {
    ListsTabView()
}
