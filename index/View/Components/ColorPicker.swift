//
//  ColorPicker.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 14/12/24.
//

import SwiftUI

fileprivate let SLIDER_HEIGHT = 34.0
fileprivate let KNOB_DIAMETER = SLIDER_HEIGHT + 4.0

struct ColorSlider: View {
    @Binding var value: Double
    let colorList: [Color]
    
    @Environment(\.self) private var environment
    @State private var currentOffset = 0.0
    @State private var isDragging: Bool = false
    @GestureState private var dragTranslation = 0.0
    
    var body: some View {
        GeometryReader { container in
            let sliderWidth = container.size.width - KNOB_DIAMETER
            
            Capsule()
                .fill(
                    LinearGradient(
                        colors: colorList,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .strokeBorder(Color.black.opacity(0.1), lineWidth: 2)
                .overlay(
                    Circle()
                        .fill(calculateKnobColor(value: value, colorList: colorList))
                        .strokeBorder(Color.white, lineWidth: isDragging ? 8 : 5)
                        .animation(.easeIn(duration: 0.1), value: isDragging)
                        .frame(height: KNOB_DIAMETER)
                        .compositingGroup()
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1.5)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .offset(
                            x: clampOffset(
                                offset: currentOffset + dragTranslation,
                                sliderWidth: sliderWidth
                            )
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($dragTranslation) { dragValue, state, _ in
                                    isDragging = true
                                    state = dragValue.translation.width
                                    value = convertOffsetToValue(
                                        offset: clampOffset(offset: currentOffset + state, sliderWidth: sliderWidth),
                                        sliderWidth: sliderWidth
                                    )
                                }
                                .onEnded { dragValue in
                                    isDragging = false
                                    currentOffset = clampOffset(
                                        offset: currentOffset + dragValue.translation.width,
                                        sliderWidth: sliderWidth
                                    )
                                }
                        )
                )
                .onAppear {
                    currentOffset = convertValueToOffset(value: value, sliderWidth: sliderWidth)
                }
        }
            .frame(height: SLIDER_HEIGHT)
    }
    
    private func clampOffset(offset: Double, sliderWidth: Double) -> Double {
        min(max(offset, -1 * sliderWidth / 2.0), sliderWidth / 2.0)
    }
    
    private func convertOffsetToValue(offset: Double, sliderWidth: Double) -> Double {
        return (offset / sliderWidth) + 0.5
    }
    
    private func convertValueToOffset(value: Double, sliderWidth: Double) -> Double {
        return (value - 0.5) * sliderWidth
    }
    
    private func calculateKnobColor(value: Double, colorList: [Color]) -> Color {
        let valueIndex = Double(colorList.count - 1) * value
        let leadingColorIndex = Int(floor(valueIndex))
        let trailingColorIndex = Int(ceil(valueIndex))
        let proportion = valueIndex - Double(leadingColorIndex)
        
        let resolvedLeadingColor = colorList[leadingColorIndex].resolve(in: environment)
        let resolvedTrailingColor = colorList[trailingColorIndex].resolve(in: environment)
        
        return Color(
            red: Double(resolvedLeadingColor.red) * (1 - proportion) + Double(resolvedTrailingColor.red) * proportion,
            green: Double(resolvedLeadingColor.green) * (1 - proportion) + Double(resolvedTrailingColor.green) * proportion,
            blue: Double(resolvedLeadingColor.blue) * (1 - proportion) + Double(resolvedTrailingColor.blue) * proportion
        )
        
    }
    
}

#Preview {
    
    @Previewable @State var hue: Double = 0.3
    @Previewable @State var lightness: Double = 0.7
    
    VStack(spacing: 27) {
        ColorSlider(
            value: $hue,
            colorList: stride(from: 0, through: 1, by: 0.2).map {
                Color(hue: $0, saturation: 0.8, brightness: 1)
            }
        )
        
        ColorSlider(
            value: $lightness,
            colorList: [
                Color(hue: hue, saturation: 0.1, brightness: 1),
                Color(hue: hue, saturation: 1.0, brightness: 0.7),
                Color(hue: hue, saturation: 1.0, brightness: 0)
            ]
        )
    }
    .padding(.horizontal, 24)
}
