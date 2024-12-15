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
    
    private var categories: [IxListCategory]
    private var namePlaceholder: String
    
    private var isNameInvalid: Bool {
        name.isEmpty || name.count >= 100
    }
    
    private var onSave: (_ name: String, _ category: IxListCategory?, _ link: String?) -> Void
    
    init(
        showSheet: Binding<Bool>,
        name: String,
        category: IxListCategory?,
        link: String?,
        categories: [IxListCategory],
        namePlaceholder: String,
        onSave: @escaping (_ name: String, _ category: IxListCategory?, _ link: String?) -> Void
    ) {
        self._showSheet = showSheet
        
        self.name = name
        self.category = category
        self.link = link ?? ""
        self.categories = categories
        self.namePlaceholder = namePlaceholder
        
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ItemCard(
                    item: IxListItem(id: UUID().uuidString, user_id: "", list_id: "", category_id: category?.id, name: name.isEmpty ? namePlaceholder : name, completed: false, link: link == "" ? nil : link, created_at: 0, edited_at: 0, completed_at: 0),
                    color: category?.color != nil ? Color(hexString: category!.color) : nil,
                    onOpen: { _ in },
                    onOpenLink: { _, _ in },
                    onCompletionChange: { _, _ in },
                    onCreateTask: { _ in },
                    onEdit: { _ in },
                    onDelete: { _ in }
                ).shadow(color: .gray.opacity(0.5), radius: 8)
                    .padding()
                    
                
                Form {
                    Section {
                        TextField("Name", text: $name)
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
                        
                        TextField("Link", text: $link)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } header: {
                        Text("Properties")
                    } footer: {
                        Text("Both the category and link are optional!")
                    }
                }
            }
            .background(UIColor.systemGroupedBackground.toColor())
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
                        onSave(name, category, link)
                        showSheet = false
                    }
                    .disabled(isNameInvalid)
                }
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
        categories: [
            IxListCategory.loading(),
            IxListCategory.loading(),
            IxListCategory.loading()
        ],
        namePlaceholder: "Item name"
    ) { name, category, link in
        // Handle save action
    }
}
