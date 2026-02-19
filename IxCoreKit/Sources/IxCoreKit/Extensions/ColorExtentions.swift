//
//  ColorExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI

public extension Color {
    /**
     Creates a color from an hex string (e.g. "#3498db"). The RGBA string are also supported (e.g. "#3498dbff").

     If the given hex string is invalid the initialiser will create a black color.

     - parameter hexString: A hexa-decimal color string representation.
     */
    init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")

        var color: UInt64 = 0

        if scanner.scanHexInt64(&color) {
            self.init(hex: color, useOpacity: hexString.count > 7)
        } else {
            self.init(hex: 0x000000)
        }
    }

    /**
     Creates a color from an hex string (e.g. "#3498db"). The RGBA string are also supported (e.g. "#3498dbff").

     If the given hex string is invalid the initialiser will return nil.

     - parameter hexString: A hexa-decimal color string representation.
     */
    init?(unsecureHexString: String) {
        let hexString = unsecureHexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")

        var color: UInt64 = 0

        if scanner.scanHexInt64(&color) {
            self.init(hex: color, useOpacity: hexString.count > 7)
        } else {
            return nil
        }
    }

    /**
     Creates a color from an hex integer (e.g. 0x3498db).

     - parameter hex: A hexa-decimal UInt64 that represents a color.
     - parameter opacityChannel: If true the given hex-decimal UInt64 includes the opacity channel (e.g. 0xFF0000FF).
     */
    init(hex: UInt64, useOpacity opacityChannel: Bool = false) {
        let mask = UInt64(0xFF)
        let cappedHex = !opacityChannel && hex > 0xFFFFFF ? 0xFFFFFF : hex

        let r = cappedHex >> (opacityChannel ? 24 : 16) & mask
        let g = cappedHex >> (opacityChannel ? 16 : 8) & mask
        let b = cappedHex >> (opacityChannel ? 8 : 0) & mask
        let o = opacityChannel ? cappedHex & mask : 255

        let red = Double(r) / 255.0
        let green = Double(g) / 255.0
        let blue = Double(b) / 255.0
        let opacity = Double(o) / 255.0

        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }

    var hexString: String {
        let cg = UIColor(self).cgColor
        let components = cg.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }

    var light: Self {
        var environment = EnvironmentValues()
        environment.colorScheme = .light
        return Color(resolve(in: environment))
    }

    var dark: Self {
        var environment = EnvironmentValues()
        environment.colorScheme = .dark
        return Color(resolve(in: environment))
    }

    /// Returns whether a color is considered light, meaning a good contrast color for it would be a dark one
    func isLight() -> Bool {
        // Convert the Color to a UIColor to access its RGB components.
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Calculate the perceptive luminance (luma)
        let luma = (0.299 * red) + (0.587 * green) + (0.114 * blue)

        return luma > 0.6
    }

    /// Returns the best contrast color (black or white) for the given color.
    func contrastColor() -> Color {
        return isLight() ? .black : .white
    }
}

public extension Color {
    static var systemRed: Color {
        Color(UIColor.systemRed)
    }

    static var systemGreen: Color {
        Color(UIColor.systemGreen)
    }

    static var systemTeal: Color {
        Color(UIColor.systemTeal)
    }

    static var systemBlue: Color {
        Color(UIColor.systemBlue)
    }

    static var systemYellow: Color {
        Color(UIColor.systemYellow)
    }

    static var systemOrange: Color {
        Color(UIColor.systemOrange)
    }

    static var systemPink: Color {
        Color(UIColor.systemPink)
    }

    static var systemPurple: Color {
        Color(UIColor.systemPurple)
    }

    static var systemIndigo: Color {
        Color(UIColor.systemIndigo)
    }

    static var systemGray: Color {
        Color(UIColor.systemGray)
    }

    static var systemGray1: Color {
        Color(UIColor.systemGray2)
    }

    static var systemGray3: Color {
        Color(UIColor.systemGray3)
    }

    static var systemGray4: Color {
        Color(UIColor.systemGray4)
    }

    static var systemGray5: Color {
        Color(UIColor.systemGray5)
    }

    static var systemGray6: Color {
        Color(UIColor.systemGray6)
    }

    static var systemPlaceholderText: Color {
        Color(UIColor.placeholderText)
    }

    static var systemLink: Color {
        Color(UIColor.link)
    }

    static var systemSeparator: Color {
        Color(UIColor.separator)
    }

    static var systemOpaqueSeparator: Color {
        Color(UIColor.opaqueSeparator)
    }

    static var systemLabel: Color {
        Color(UIColor.label)
    }

    static var systemLabelSecondary: Color {
        Color(UIColor.secondaryLabel)
    }

    static var systemLabelTertiary: Color {
        Color(UIColor.tertiaryLabel)
    }

    static var systemLabelQuaternary: Color {
        Color(UIColor.quaternaryLabel)
    }

    static var systemFill: Color {
        Color(UIColor.systemFill)
    }

    static var systemFillSecondary: Color {
        Color(UIColor.secondarySystemFill)
    }

    static var systemFillTertiary: Color {
        Color(UIColor.tertiarySystemFill)
    }

    static var systemFillQuaternary: Color {
        Color(UIColor.quaternarySystemFill)
    }

    static var systemBackground: Color {
        Color(UIColor.systemBackground)
    }

    static var systemBackgroundSecondary: Color {
        Color(UIColor.secondarySystemBackground)
    }

    static var systemBackgroundTertiary: Color {
        Color(UIColor.tertiarySystemBackground)
    }

    static var systemGroupedBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }

    static var systemSecondaryGroupedBackground: Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }

    static var systemTertiaryGroupedBackground: Color {
        Color(UIColor.tertiarySystemGroupedBackground)
    }
}

// TODO: Add to app target
extension Color: @retroactive Identifiable {
    public var id: String {
        hexString
    }
}

public extension UIColor {
    func toColor() -> Color {
        return Color(self)
    }
}

public extension CGColor {
    func toColor() -> Color {
        return Color(self)
    }
}

public extension String {
    func toColor() -> Color {
        return .init(hexString: self)
    }

    func toColorOrNil() -> Color? {
        return Color(unsecureHexString: self)
    }
}
