//
//  ItemFormSheet.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 15/12/24.
//

import SwiftUI

struct ItemFormSheet: View {
    @Binding var showSheet: Bool
    
    @FocusState private var isNameFocused: Bool
    
    @State private var name: String
    @State private var category: IxListCategory?
    @State private var link: String
    @State private var note: String
    
    private var categories: [IxListCategory]
    private var namePlaceholder: String
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }
    
    private var onSave: (_ name: String, _ category: IxListCategory?, _ link: String?, _ note: String?) -> Void
    
    init(
        showSheet: Binding<Bool>,
        name: String,
        category: IxListCategory?,
        link: String?,
        note: String?,
        categories: [IxListCategory],
        namePlaceholder: String,
        onSave: @escaping (_ name: String, _ category: IxListCategory?, _ link: String?, _ note: String?) -> Void
    ) {
        self._showSheet = showSheet
        self.name = name
        self.category = category
        self.link = link ?? ""
        self.note = note ?? ""
        self.categories = categories.sorted {
            $0.name < $1.name
        }
        self.namePlaceholder = namePlaceholder
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField(namePlaceholder, text: $name, axis: .vertical)
                            .focused($isNameFocused)
                    } header: {
                        Text("Name")
                    }
                    
                    Section {
                        Picker("Category", selection: $category) {
                            Text("No category").tag(nil as IxListCategory?)
                            
                            ForEach(categories, id: \.id) { category in
                                Text(category.name).tag(category as IxListCategory?)
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
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showSheet = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, category, link.isEmpty ? nil : link, note.isEmpty ? nil : note)
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

    ItemFormSheet(
        showSheet: $show,
        name: "",
        category: nil,
        link: nil,
        note: nil,
        categories: [
            IxListCategory.loading(),
            IxListCategory.loading(),
            IxListCategory.loading()
        ],
        namePlaceholder: "Item name"
    ) { name, category, link, note in
        // Handle save action
    }
}
