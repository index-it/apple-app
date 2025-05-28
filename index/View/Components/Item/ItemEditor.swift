//
//  ItemFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/12/24.
//

import SwiftUI
import IxCoreKit

struct ItemEditor: View {
    @Binding var isPresented: Bool
    
    private var addingNew: Bool
    @FocusState private var isNameFocused: Bool
    @State private var name: String
    @State private var categoryId: String?
    @State private var link: String
    @State private var note: String
    
    private var categories: [IxListCategory]
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }
    
    private var onSave: (_ name: String, _ categoryId: String?, _ link: String?, _ note: String?) -> Void
    
    init(
        isPresented: Binding<Bool>,
        addingNew: Bool,
        name: String,
        categoryId: String?,
        link: String?,
        note: String?,
        categories: [IxListCategory],
        onSave: @escaping (_ name: String, _ categoryId: String?, _ link: String?, _ note: String?) -> Void
    ) {
        self._isPresented = isPresented
        self.addingNew = addingNew
        
        self.name = name
        self.categoryId = categoryId
        self.link = link ?? ""
        self.note = note ?? ""
        
        self.categories = categories.sorted {
            $0.name < $1.name
        }
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Name", text: $name, axis: .vertical)
                        .focused($isNameFocused)
                    
                    Section {
                        Picker("Category", selection: $categoryId) {
                            Text("No category").tag(nil as String?)
                            
                            ForEach(categories, id: \.id) { category in
                                Text(category.name).tag(category.id)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Link", text: $link, axis: .vertical)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            
                        TextField("Notes", text: $note,  axis: .vertical)
                            .lineLimit(3...)
                    } header: {
                        Text("Properties")
                    } footer: {
                        Text("All properties are optional")
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle(addingNew ? "Add Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, categoryId, link.isEmpty ? nil : link, note.isEmpty ? nil : note)
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
    @Previewable @State var isPresented = false
    
    ItemEditor(
        isPresented: $isPresented,
        addingNew: true,
        name: "",
        categoryId: nil,
        link: nil,
        note: nil,
        categories: []
    ) { name, categoryId, link, note in
        
    }
}
