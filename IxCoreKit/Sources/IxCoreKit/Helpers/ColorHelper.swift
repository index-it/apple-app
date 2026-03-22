//
//  ColorHelper.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 05/05/25.
//

import SwiftUI

public enum ColorHelper {
    public static let ixColors = [
        Color(hexString: "#88CCFA"),
        Color(hexString: "#14704A"),
        Color(hexString: "#FF3D2F"),
        Color(hexString: "#FE9500"),
        Color(hexString: "#FFCC02"),
        Color(hexString: "#19C759"),
        Color(hexString: "#50ABF2"),
        Color(hexString: "#047AFF"),
        Color(hexString: "#5856D5"),
        Color(hexString: "#EA416A"),
        Color(hexString: "#C077DC"),
        Color(hexString: "#9D8563"),
        Color(hexString: "#5B6770"),
        Color(hexString: "#DAA69E"),
        Color(hexString: "#FBA592"),
        Color(hexString: "#A41D1A"),
        Color(hexString: "#DB4319"),
        Color(hexString: "#199B7F"),
    ]

    public static func randomIxColor() -> Color {
        return ixColors.randomElement() ?? Color.accentColor
    }
}
