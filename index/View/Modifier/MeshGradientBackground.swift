//
//  MeshGradientBackground.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/10/24.
//

import SwiftUI

struct MeshGradientBackground: ViewModifier {
    @Environment(\.colorScheme) var currentScheme

    @State var t: Float = 0.0
    @State var timer: Timer?

    private var colors: [Color] {
        currentScheme == .light ? [
            Color(red: 220 / 255, green: 240 / 255, blue: 255 / 255), // Very light blue
            Color(red: 190 / 255, green: 225 / 255, blue: 252 / 255), // Soft light blue
            Color(red: 160 / 255, green: 215 / 255, blue: 251 / 255), // Light sky blue
            Color(red: 136 / 255, green: 204 / 255, blue: 250 / 255), // Base color
            Color(red: 150 / 255, green: 210 / 255, blue: 245 / 255), // Slight variation
            Color(red: 175 / 255, green: 220 / 255, blue: 248 / 255), // Blending tone
            Color(red: 200 / 255, green: 230 / 255, blue: 252 / 255), // Soft highlight
            Color(red: 210 / 255, green: 235 / 255, blue: 255 / 255), // Almost white blue
            Color(red: 170 / 255, green: 215 / 255, blue: 245 / 255), // Mid tone
        ] : [
            Color(red: 10 / 255, green: 25 / 255, blue: 40 / 255),  // Deep navy
            Color(red: 15 / 255, green: 40 / 255, blue: 70 / 255),  // Dark blue
            Color(red: 20 / 255, green: 55 / 255, blue: 90 / 255),  // Muted blue
            Color(red: 30 / 255, green: 80 / 255, blue: 120 / 255), // Desaturated blue
            Color(red: 40 / 255, green: 100 / 255, blue: 150 / 255), // Darker base tone
            Color(red: 25 / 255, green: 70 / 255, blue: 110 / 255), // Blend tone
            Color(red: 35 / 255, green: 90 / 255, blue: 140 / 255), // Soft dark blue
            Color(red: 20 / 255, green: 60 / 255, blue: 100 / 255), // Depth tone
            Color(red: 10 / 255, green: 35 / 255, blue: 60 / 255),  // Very dark blue
        ]
    }

    func sinInRange(_ range: ClosedRange<Float>, offset: Float, timeScale: Float, t: Float) -> Float {
        let amplitude = (range.upperBound - range.lowerBound) / 2
        let midPoint = (range.upperBound + range.lowerBound) / 2
        return midPoint + amplitude * sin(timeScale * t + offset)
    }

    func body(content: Content) -> some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0, 0), .init(0.5, 0), .init(1, 0),
                    [sinInRange(-0.8 ... -0.2, offset: 0.439, timeScale: 0.342, t: t), sinInRange(0.3 ... 0.7, offset: 3.42, timeScale: 0.984, t: t)],
                    [sinInRange(0.1 ... 0.8, offset: 0.239, timeScale: 0.084, t: t), sinInRange(0.2 ... 0.8, offset: 5.21, timeScale: 0.242, t: t)],
                    [sinInRange(1.0 ... 1.5, offset: 0.939, timeScale: 0.084, t: t), sinInRange(0.4 ... 0.8, offset: 0.25, timeScale: 0.642, t: t)],
                    [sinInRange(-0.8 ... 0.0, offset: 1.439, timeScale: 0.442, t: t), sinInRange(1.4 ... 1.9, offset: 3.42, timeScale: 0.984, t: t)],
                    [sinInRange(0.3 ... 0.6, offset: 0.339, timeScale: 0.784, t: t), sinInRange(1.0 ... 1.2, offset: 1.22, timeScale: 0.772, t: t)],
                    [sinInRange(1.0 ... 1.5, offset: 0.939, timeScale: 0.056, t: t), sinInRange(1.3 ... 1.7, offset: 0.47, timeScale: 0.342, t: t)],
                ],
                colors: colors
            )
            .ignoresSafeArea()

            content
        }.onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                t += 0.04
            }
        }
    }
}

extension View {
    func meshGradientBackground() -> some View {
        modifier(MeshGradientBackground())
    }
}

#Preview {
    VStack {}
        .frame(minWidth: 1920, minHeight: 1080)
        .meshGradientBackground()
}
