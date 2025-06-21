//
//  ColorSelector.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 14/12/24.
//

import SwiftUI

struct ColorSelector: View {
    @Binding var color: Color
    var colors: [Color]
    
    @State var hue: Double = 0.3
    @State var brightness: Double = 0.7
    @State var saturation: Double = 0.6
    @State private var showColorPicker = false
    
    private var gradientColorList = stride(from: 0, through: 1, by: 0.2).map {
        Color(hue: $0, saturation: 0.8, brightness: 1)
    }
    
    init(
        color: Binding<Color>,
        colors: [Color]
    ) {
        self._color = color
        self.colors = colors
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    Button {
                        withAnimation {
                            self.color = Color(hue: hue, saturation: 1, brightness: brightness)
                            showColorPicker = true
                        }
                    } label: {
                        AngularGradient(
                            gradient: Gradient(colors: stride(from: 0, through: 1, by: 0.2).map {
                                Color(hue: $0, saturation: 1, brightness: 1)
                            }),
                            center: .center
                        )
                        .blur(radius: 4, opaque: true)
                        .clipShape(Circle())
                        .scaledToFill()
                        .overlay {
                            if showColorPicker {
                                Circle()
                                    .fill(.white)
                                    .padding(.all, 10)
                                    
                            }
                        }
                        .scrollTransition { content, phase in
                            content.blur(radius: phase.isIdentity ? 0 : 8)
                        }
                    }
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary)
                        .frame(width: 1, height: 28)
                        .edgesIgnoringSafeArea(.horizontal)
                    
                    ForEach(colors, id: \.hashValue) { color in
                        Circle()
                            .fill(color)
                            .overlay {
                                if self.color == color {
                                    Circle()
                                        .fill(.white)
                                        .padding(.all, 10)
                                        
                                }
                            }
                            .onTapGesture {
                                withAnimation {
                                    self.color = color
                                    showColorPicker = false
                                }
                            }
                            .scrollTransition { content, phase in
                                content.blur(radius: phase.isIdentity ? 0 : 8)
                            }
                    }
                }.scrollTargetLayout()
                .frame(height: 42)
            }
            
            if showColorPicker {
                VStack(spacing: 27) {
                    ColorSlider(
                        value: $hue,
                        colorList: gradientColorList
                    )
                    
                    ColorSlider(
                        value: $brightness,
                        colorList: [
                            Color(hue: hue, saturation: saturation, brightness: 0.1),
                            Color(hue: hue, saturation: saturation, brightness: 0.9),
                        ]
                    )
                    
                    ColorSlider(
                        value: $saturation,
                        colorList: [
                            Color(hue: hue, saturation: 0.1, brightness: brightness),
                            Color(hue: hue, saturation: 0.9, brightness: brightness),
                        ]
                    )
                }.padding([.top, .bottom], 24)
            }
        }
        .onChange(of: hue) { _, newValue in
            withAnimation {
                self.color = Color(hue: newValue, saturation: saturation, brightness: brightness)
            }
        }
        .onChange(of: brightness) { _, newValue in
            withAnimation {
                self.color = Color(hue: hue, saturation: saturation, brightness: newValue)
            }
        }
        .onChange(of: saturation) { _, newValue in
            withAnimation {
                self.color = Color(hue: hue, saturation: newValue, brightness: brightness)
            }
        }
    }
}

#Preview {
    @Previewable @State var color = Color.red
    
    VStack {
        color
            .frame(width: 50, height: 50)
            .padding(.bottom, 24)
        
        ColorSelector(color: $color, colors: [.red, .green, .yellow, .blue, .pink, .purple, .black])
        
    }.padding()
}
