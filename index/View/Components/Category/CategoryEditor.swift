//
//  CategoryFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/12/24.
//

import SwiftUI
import IxCoreKit

struct CategoryEditor: View {
    @Binding var isPresented: Bool
    
    private var addingNew: Bool
    @FocusState private var isNameFocused: Bool
    @State private var name: String
    @State private var color: Color
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }

    private var onSave: (_ name: String, _ color: Color) -> Void
    
    init(
        isPresented: Binding<Bool>,
        addingNew: Bool = true,
        name: String = "",
        color: Color? = ColorHelper.randomIxColor(),
        onSave: @escaping (_ name: String, _ color: Color) -> Void
    ) {
        self._isPresented = isPresented
        self.addingNew = addingNew
        self.name = name
        self.color = color ?? ColorHelper.randomIxColor()
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                    
                    Section {
                        ColorSelector(color: $color, colors: ColorHelper.ixColors)
                    } header: {
                        Text("Color")
                    } footer: {
                        Text("Scroll horizontally for more colors")
                    }
                }
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle(addingNew ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, color)
                        isPresented = false
                    }
                    .disabled(isNameInvalid)
                }
            }
            .onAppear {
                if addingNew {
                    isNameFocused = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true

    CategoryEditor(
        isPresented: $isPresented,
    ) { name, color in
        
    }
}
