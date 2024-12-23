//
//  ColorExtentions.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import SwiftUI

extension Color {
    init(hex: String, fallback: Color) {
        do {
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let a, r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (1, 1, 1, 0)
            }
            
            self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue:  Double(b) / 255,
                opacity: Double(a) / 255
            )
        } catch {
            self.init(fallback)
        }
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
        
        return luma <= 0.6
    }
    
    /// Returns the best contrast color (black or white) for the given color.
    func contrastColor() -> Color {
        // Convert the Color to a UIColor to access its RGB components.
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate the perceptive luminance (luma)
        let luma = (0.299 * red) + (0.587 * green) + (0.114 * blue)
        
        // Return black for bright colors, white for dark colors
        return luma > 0.6 ? .black : .white
    }
    
    func hexString() -> String {
        return UIColor(self).toHexString()
    }
}

extension UIColor {
    func toColor() -> Color {
        return Color(self)
    }
}

extension String {
    func toColor(fallback: Color) -> Color {
        return .init(hex: self, fallback: fallback)
    }
}
