//
//  ItemFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/12/24.
//

import SwiftUI
import IxCoreKit

fileprivate enum FocusField: Hashable {
    case name
    case link
    case note
}

struct ItemEditor: View {
    @Binding var isPresented: Bool
    @FocusState private var focusField: FocusField?

    private var addingNew: Bool
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
    
    private func onSubmit() {
        if (!isNameInvalid) {
            onSave(name, categoryId, link.isEmpty ? nil : link, note.isEmpty ? nil : note)
            isPresented = false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    TextField("Name", text: $name)
                        .focused($focusField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusField = .link
                        }
                    
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
                            .focused($focusField, equals: .link)
                            .submitLabel(.next)
                            .onSubmit {
                                focusField = .note
                            }
                            
                        TextField("Notes", text: $note,  axis: .vertical)
                            .lineLimit(3...)
                            .focused($focusField, equals: .note)
                            .submitLabel(.done)
                            .onSubmit {
                                onSubmit()
                            }
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
                        onSubmit()
                    }
                    .disabled(isNameInvalid)
                }
            }
            .onAppear {
                if addingNew {
                    focusField = .name
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
