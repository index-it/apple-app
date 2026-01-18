//
//  TextFieldClearButton.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/10/24.
//

import Foundation
import SwiftUI

struct TextFieldClearButton: ViewModifier {
    @Binding var fieldText: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if !fieldText.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            fieldText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.large)
                        }
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                    }
                }
            }
    }
}

extension View {
    func showClearButton(_ text: Binding<String>) -> some View {
        modifier(TextFieldClearButton(fieldText: text))
    }
}
