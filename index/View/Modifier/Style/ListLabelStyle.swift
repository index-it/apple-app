//
//  ListLabelStyle.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/02/25.
//

import SwiftUI

struct ListLabelStyle: LabelStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .font(.system(size: 12))
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 7).frame(width: 28, height: 28).foregroundColor(color))
        }
    }
}
