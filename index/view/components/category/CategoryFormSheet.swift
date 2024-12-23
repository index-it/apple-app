//
//  CategoryFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/12/24.
//

import SwiftUI

struct CategoryFormSheet: View {
    @Binding var showSheet: Bool
    
    @FocusState private var isNameFocused: Bool
    
    @State private var namePlaceholder: String
    @State private var name: String
    @State private var color: Color
    private var colors: [Color]
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }

    private var onSave: (_ name: String, _ color: Color) -> Void
    
    init(
        showSheet: Binding<Bool>,
        name: String,
        color: Color,
        namePlaceholder: String,
        colors: [Color],
        onSave: @escaping (_ name: String, _ color: Color) -> Void
    ) {
        self._showSheet = showSheet
        
        self.name = name
        self.color = color
        self.namePlaceholder = namePlaceholder
        self.colors = colors
        
        self.onSave = onSave
    }
        
        
    
    var body: some View {
        NavigationView {
            VStack {
                
                Form {
                    Section {
                        TextField(namePlaceholder, text: $name)
                            .focused($isNameFocused)
                    } header: {
                        Text("Name")
                    }
                    
                    Section {
                        ColorSelector(color: $color, colors: colors)
                    } header: {
                        Text("Color")
                    } footer: {
                        Text("Scroll horizontally for more colors")
                    }
                }
                
          
            }
            .background(Color(UIColor.systemGroupedBackground))
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showSheet = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, color)
                        showSheet = false
                    }
                    .disabled(isNameInvalid)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
}

#Preview {
    @Previewable @State var show = true

    CategoryFormSheet(showSheet: $show, name: "", color: Color.red, namePlaceholder: "Name", colors: [.red, .yellow, .purple, .pink, .blue]) { name, color in
        
    }
}
