//
//  ListColor.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import SwiftUI
import IxCoreKit

enum IxColorEnum: String, Hashable, Identifiable, CaseIterable, AppEnum {
    case darkGreen
    case red
    case orange
    case yellow
    case green
    case lightBlue
    case blue
    case purple
    case pink
    case lavender
    case brown
    case gray
    case beige
    case peach
    case darkRed
    case brightRed
    case teal

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(
            name: LocalizedStringResource("Color", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) colors"
        )
    }

    static var caseDisplayRepresentations: [IxColorEnum: DisplayRepresentation] = [
        .darkGreen: DisplayRepresentation(title: "Dark Green", image: nil),
        .red: DisplayRepresentation(title: "Red", image: nil),
        .orange: DisplayRepresentation(title: "Orange", image: nil),
        .yellow: DisplayRepresentation(title: "Yellow", image: nil),
        .green: DisplayRepresentation(title: "Green", image: nil),
        .lightBlue: DisplayRepresentation(title: "Light Blue", image: nil),
        .blue: DisplayRepresentation(title: "Blue", image: nil),
        .purple: DisplayRepresentation(title: "Purple", image: nil),
        .pink: DisplayRepresentation(title: "Pink", image: nil),
        .lavender: DisplayRepresentation(title: "Lavender", image: nil),
        .brown: DisplayRepresentation(title: "Brown", image: nil),
        .gray: DisplayRepresentation(title: "Gray", image: nil),
        .beige: DisplayRepresentation(title: "Beige", image: nil),
        .peach: DisplayRepresentation(title: "Peach", image: nil),
        .darkRed: DisplayRepresentation(title: "Dark Red", image: nil),
        .brightRed: DisplayRepresentation(title: "Bright Red", image: nil),
        .teal: DisplayRepresentation(title: "Teal", image: nil),
    ]

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .darkGreen: return Color(hexString: "#14704A")
        case .red: return Color(hexString: "#FF3D2F")
        case .orange: return Color(hexString: "#FE9500")
        case .yellow: return Color(hexString: "#FFCC02")
        case .green: return Color(hexString: "#19C759")
        case .lightBlue: return Color(hexString: "#50ABF2")
        case .blue: return Color(hexString: "#047AFF")
        case .purple: return Color(hexString: "#5856D5")
        case .pink: return Color(hexString: "#EA416A")
        case .lavender: return Color(hexString: "#C077DC")
        case .brown: return Color(hexString: "#9D8563")
        case .gray: return Color(hexString: "#5B6770")
        case .beige: return Color(hexString: "#DAA69E")
        case .peach: return Color(hexString: "#FBA592")
        case .darkRed: return Color(hexString: "#A41D1A")
        case .brightRed: return Color(hexString: "#DB4319")
        case .teal: return Color(hexString: "#199B7F")
        }
    }
}
