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
            Color(red: 237/255, green: 255/255, blue: 242/255), // Light mint green
            Color(red: 185/255, green: 250/255, blue: 194/255), // Pale green
            Color(red: 235/255, green: 252/255, blue: 237/255), // Soft green
            Color(red: 210/255, green: 245/255, blue: 200/255), // Additional soft green
            Color(red: 240/255, green: 245/255, blue: 240/255), // Soft grey-green for extra blending
            Color(red: 200/255, green: 240/255, blue: 210/255), // Extra green tone for variety
            Color(red: 220/255, green: 250/255, blue: 230/255), // Light blending tone
            Color(red: 215/255, green: 255/255, blue: 235/255), // Soft minty finish
            Color(red: 195/255, green: 235/255, blue: 210/255)  // Deep soft green
        ] : [
            Color(red: 10/255, green: 30/255, blue: 20/255),  // Darker mint green
            Color(red: 5/255, green: 50/255, blue: 25/255),   // Dark green
            Color(red: 15/255, green: 60/255, blue: 30/255),  // Deep forest green
            Color(red: 20/255, green: 55/255, blue: 45/255),  // Muted dark green
            Color(red: 10/255, green: 25/255, blue: 15/255),  // Dark olive green
            Color(red: 15/255, green: 40/255, blue: 25/255),  // Deep moss green
            Color(red: 20/255, green: 50/255, blue: 35/255),  // Dark teal
            Color(red: 25/255, green: 65/255, blue: 45/255),  // Muted dark teal
            Color(red: 5/255, green: 20/255, blue: 15/255)    // Very dark green
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
                    [sinInRange(-0.8...(-0.2), offset: 0.439, timeScale: 0.342, t: t), sinInRange(0.3...0.7, offset: 3.42, timeScale: 0.984, t: t)],
                    [sinInRange(0.1...0.8, offset: 0.239, timeScale: 0.084, t: t), sinInRange(0.2...0.8, offset: 5.21, timeScale: 0.242, t: t)],
                    [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.084, t: t), sinInRange(0.4...0.8, offset: 0.25, timeScale: 0.642, t: t)],
                    [sinInRange(-0.8...0.0, offset: 1.439, timeScale: 0.442, t: t), sinInRange(1.4...1.9, offset: 3.42, timeScale: 0.984, t: t)],
                    [sinInRange(0.3...0.6, offset: 0.339, timeScale: 0.784, t: t), sinInRange(1.0...1.2, offset: 1.22, timeScale: 0.772, t: t)],
                    [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.056, t: t), sinInRange(1.3...1.7, offset: 0.47, timeScale: 0.342, t: t)]
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
    VStack {
        
    }
    .frame(minWidth: 1920, minHeight: 1080)
    .meshGradientBackground()
}
