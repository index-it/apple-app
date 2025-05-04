//
//  ColorExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI


@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension Color {
    /**
     Creates a color from an hex string (e.g. "#3498db"). The RGBA string are also supported (e.g. "#3498dbff").

     If the given hex string is invalid the initialiser will create a black color.

     - parameter hexString: A hexa-decimal color string representation.
     */
    init(hexString: String) {
      let hexString                 = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
      let scanner                   = Scanner(string: hexString)
      scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")

      var color: UInt64 = 0

      if scanner.scanHexInt64(&color) {
        self.init(hex: color, useOpacity: hexString.count > 7)
      }
      else {
        self.init(hex: 0x000000)
      }
    }
    
    /**
     Creates a color from an hex string (e.g. "#3498db"). The RGBA string are also supported (e.g. "#3498dbff").

     If the given hex string is invalid the initialiser will return nil.

     - parameter hexString: A hexa-decimal color string representation.
     */
    init?(unsecureHexString: String) {
      let hexString                 = unsecureHexString.trimmingCharacters(in: .whitespacesAndNewlines)
      let scanner                   = Scanner(string: hexString)
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
      let mask      = UInt64(0xFF)
      let cappedHex = !opacityChannel && hex > 0xffffff ? 0xffffff : hex

      let r = cappedHex >> (opacityChannel ? 24 : 16) & mask
      let g = cappedHex >> (opacityChannel ? 16 : 8) & mask
      let b = cappedHex >> (opacityChannel ? 8 : 0) & mask
      let o = opacityChannel ? cappedHex & mask : 255

      let red     = Double(r) / 255.0
      let green   = Double(g) / 255.0
      let blue    = Double(b) / 255.0
      let opacity = Double(o) / 255.0

      self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    func hexString() -> String {
        return UIColor(self).toHexString()
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
        return self.isLight() ? .black : .white
    }

}

extension Color: @retroactive Identifiable {
    public var id: String { self.hexString() }
}

extension UIColor {
    func toColor() -> Color {
        return Color(self)
    }
}

extension String {
    func toColor(fallback: Color) -> Color {
        return .init(hexString: self)
    }
    
    func toColorOrNil() -> Color? {
        return Color(unsecureHexString: self)
    }
}
